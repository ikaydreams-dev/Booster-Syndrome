package main

import (
	"crypto/sha256"
	"encoding/binary"
	"sync"
	"time"
)

type ConsistentHash struct {
	circle       map[uint32]string
	sortedHashes []uint32
	nodes        map[string]bool
	replicas     int
	mu           sync.RWMutex
}

func NewConsistentHash(replicas int) *ConsistentHash {
	return &ConsistentHash{
		circle:   make(map[uint32]string),
		nodes:    make(map[string]bool),
		replicas: replicas,
	}
}

func (ch *ConsistentHash) AddNode(node string) {
	ch.mu.Lock()
	defer ch.mu.Unlock()

	if ch.nodes[node] {
		return
	}

	ch.nodes[node] = true
	for i := 0; i < ch.replicas; i++ {
		hash := ch.hashKey(node + string(rune(i)))
		ch.circle[hash] = node
		ch.sortedHashes = append(ch.sortedHashes, hash)
	}
	ch.sortHashes()
}

func (ch *ConsistentHash) RemoveNode(node string) {
	ch.mu.Lock()
	defer ch.mu.Unlock()

	if !ch.nodes[node] {
		return
	}

	delete(ch.nodes, node)
	for i := 0; i < ch.replicas; i++ {
		hash := ch.hashKey(node + string(rune(i)))
		delete(ch.circle, hash)
	}
	ch.rebuildSortedHashes()
}

func (ch *ConsistentHash) GetNode(key string) string {
	ch.mu.RLock()
	defer ch.mu.RUnlock()

	if len(ch.circle) == 0 {
		return ""
	}

	hash := ch.hashKey(key)
	idx := ch.search(hash)
	return ch.circle[ch.sortedHashes[idx]]
}

func (ch *ConsistentHash) hashKey(key string) uint32 {
	h := sha256.Sum256([]byte(key))
	return binary.BigEndian.Uint32(h[:4])
}

func (ch *ConsistentHash) search(hash uint32) int {
	idx := 0
	for i, h := range ch.sortedHashes {
		if h >= hash {
			idx = i
			break
		}
	}
	return idx
}

func (ch *ConsistentHash) sortHashes() {
	for i := 0; i < len(ch.sortedHashes); i++ {
		for j := i + 1; j < len(ch.sortedHashes); j++ {
			if ch.sortedHashes[i] > ch.sortedHashes[j] {
				ch.sortedHashes[i], ch.sortedHashes[j] = ch.sortedHashes[j], ch.sortedHashes[i]
			}
		}
	}
}

func (ch *ConsistentHash) rebuildSortedHashes() {
	ch.sortedHashes = make([]uint32, 0, len(ch.circle))
	for hash := range ch.circle {
		ch.sortedHashes = append(ch.sortedHashes, hash)
	}
	ch.sortHashes()
}

type CacheEntry struct {
	value      interface{}
	expiration time.Time
	version    int64
}

type DistributedCache struct {
	data       map[string]*CacheEntry
	consistentHash *ConsistentHash
	nodes      []string
	mu         sync.RWMutex
	version    int64
}

func NewDistributedCache(nodes []string) *DistributedCache {
	ch := NewConsistentHash(150)
	for _, node := range nodes {
		ch.AddNode(node)
	}

	return &DistributedCache{
		data:           make(map[string]*CacheEntry),
		consistentHash: ch,
		nodes:          nodes,
		version:        0,
	}
}

func (dc *DistributedCache) Set(key string, value interface{}, ttl time.Duration) {
	dc.mu.Lock()
	defer dc.mu.Unlock()

	dc.version++
	dc.data[key] = &CacheEntry{
		value:      value,
		expiration: time.Now().Add(ttl),
		version:    dc.version,
	}
}

func (dc *DistributedCache) Get(key string) (interface{}, bool) {
	dc.mu.RLock()
	defer dc.mu.RUnlock()

	entry, exists := dc.data[key]
	if !exists {
		return nil, false
	}

	if time.Now().After(entry.expiration) {
		return nil, false
	}

	return entry.value, true
}

func (dc *DistributedCache) Delete(key string) {
	dc.mu.Lock()
	defer dc.mu.Unlock()
	delete(dc.data, key)
}

func (dc *DistributedCache) GetNode(key string) string {
	return dc.consistentHash.GetNode(key)
}

func (dc *DistributedCache) AddNode(node string) {
	dc.mu.Lock()
	defer dc.mu.Unlock()

	dc.nodes = append(dc.nodes, node)
	dc.consistentHash.AddNode(node)
}

func (dc *DistributedCache) RemoveNode(node string) {
	dc.mu.Lock()
	defer dc.mu.Unlock()

	for i, n := range dc.nodes {
		if n == node {
			dc.nodes = append(dc.nodes[:i], dc.nodes[i+1:]...)
			break
		}
	}
	dc.consistentHash.RemoveNode(node)
}

type LRUCache struct {
	capacity int
	cache    map[string]*LRUNode
	head     *LRUNode
	tail     *LRUNode
	mu       sync.Mutex
}

type LRUNode struct {
	key   string
	value interface{}
	prev  *LRUNode
	next  *LRUNode
}

func NewLRUCache(capacity int) *LRUCache {
	head := &LRUNode{}
	tail := &LRUNode{}
	head.next = tail
	tail.prev = head

	return &LRUCache{
		capacity: capacity,
		cache:    make(map[string]*LRUNode),
		head:     head,
		tail:     tail,
	}
}

func (lru *LRUCache) Get(key string) (interface{}, bool) {
	lru.mu.Lock()
	defer lru.mu.Unlock()

	if node, exists := lru.cache[key]; exists {
		lru.moveToFront(node)
		return node.value, true
	}
	return nil, false
}

func (lru *LRUCache) Put(key string, value interface{}) {
	lru.mu.Lock()
	defer lru.mu.Unlock()

	if node, exists := lru.cache[key]; exists {
		node.value = value
		lru.moveToFront(node)
		return
	}

	newNode := &LRUNode{key: key, value: value}
	lru.cache[key] = newNode
	lru.addToFront(newNode)

	if len(lru.cache) > lru.capacity {
		removed := lru.removeTail()
		delete(lru.cache, removed.key)
	}
}

func (lru *LRUCache) moveToFront(node *LRUNode) {
	lru.removeNode(node)
	lru.addToFront(node)
}

func (lru *LRUCache) addToFront(node *LRUNode) {
	node.next = lru.head.next
	node.prev = lru.head
	lru.head.next.prev = node
	lru.head.next = node
}

func (lru *LRUCache) removeNode(node *LRUNode) {
	node.prev.next = node.next
	node.next.prev = node.prev
}

func (lru *LRUCache) removeTail() *LRUNode {
	node := lru.tail.prev
	lru.removeNode(node)
	return node
}

type BloomFilter struct {
	bitset []bool
	size   int
	hashes int
	mu     sync.RWMutex
}

func NewBloomFilter(size, hashes int) *BloomFilter {
	return &BloomFilter{
		bitset: make([]bool, size),
		size:   size,
		hashes: hashes,
	}
}

func (bf *BloomFilter) Add(key string) {
	bf.mu.Lock()
	defer bf.mu.Unlock()

	for i := 0; i < bf.hashes; i++ {
		hash := bf.hash(key, i)
		bf.bitset[hash] = true
	}
}

func (bf *BloomFilter) Contains(key string) bool {
	bf.mu.RLock()
	defer bf.mu.RUnlock()

	for i := 0; i < bf.hashes; i++ {
		hash := bf.hash(key, i)
		if !bf.bitset[hash] {
			return false
		}
	}
	return true
}

func (bf *BloomFilter) hash(key string, seed int) int {
	h := sha256.Sum256([]byte(key + string(rune(seed))))
	return int(binary.BigEndian.Uint32(h[:4])) % bf.size
}

type CuckooFilter struct {
	buckets    [][]string
	size       int
	bucketSize int
	mu         sync.RWMutex
}

func NewCuckooFilter(size, bucketSize int) *CuckooFilter {
	buckets := make([][]string, size)
	for i := range buckets {
		buckets[i] = make([]string, 0, bucketSize)
	}

	return &CuckooFilter{
		buckets:    buckets,
		size:       size,
		bucketSize: bucketSize,
	}
}

func (cf *CuckooFilter) Insert(key string) bool {
	cf.mu.Lock()
	defer cf.mu.Unlock()

	i1 := cf.hash1(key)
	if len(cf.buckets[i1]) < cf.bucketSize {
		cf.buckets[i1] = append(cf.buckets[i1], key)
		return true
	}

	i2 := cf.hash2(key)
	if len(cf.buckets[i2]) < cf.bucketSize {
		cf.buckets[i2] = append(cf.buckets[i2], key)
		return true
	}

	return false
}

func (cf *CuckooFilter) Contains(key string) bool {
	cf.mu.RLock()
	defer cf.mu.RUnlock()

	i1 := cf.hash1(key)
	for _, k := range cf.buckets[i1] {
		if k == key {
			return true
		}
	}

	i2 := cf.hash2(key)
	for _, k := range cf.buckets[i2] {
		if k == key {
			return true
		}
	}

	return false
}

func (cf *CuckooFilter) hash1(key string) int {
	h := sha256.Sum256([]byte(key))
	return int(binary.BigEndian.Uint32(h[:4])) % cf.size
}

func (cf *CuckooFilter) hash2(key string) int {
	h := sha256.Sum256([]byte(key + "salt"))
	return int(binary.BigEndian.Uint32(h[:4])) % cf.size
}

type SkipList struct {
	head      *SkipNode
	level     int
	maxLevel  int
	mu        sync.RWMutex
}

type SkipNode struct {
	key     string
	value   interface{}
	forward []*SkipNode
}

func NewSkipList(maxLevel int) *SkipList {
	return &SkipList{
		head:     &SkipNode{forward: make([]*SkipNode, maxLevel)},
		level:    0,
		maxLevel: maxLevel,
	}
}

func (sl *SkipList) Insert(key string, value interface{}) {
	sl.mu.Lock()
	defer sl.mu.Unlock()

	update := make([]*SkipNode, sl.maxLevel)
	current := sl.head

	for i := sl.level - 1; i >= 0; i-- {
		for current.forward[i] != nil && current.forward[i].key < key {
			current = current.forward[i]
		}
		update[i] = current
	}

	level := sl.randomLevel()
	if level > sl.level {
		for i := sl.level; i < level; i++ {
			update[i] = sl.head
		}
		sl.level = level
	}

	newNode := &SkipNode{
		key:     key,
		value:   value,
		forward: make([]*SkipNode, level),
	}

	for i := 0; i < level; i++ {
		newNode.forward[i] = update[i].forward[i]
		update[i].forward[i] = newNode
	}
}

func (sl *SkipList) Search(key string) (interface{}, bool) {
	sl.mu.RLock()
	defer sl.mu.RUnlock()

	current := sl.head
	for i := sl.level - 1; i >= 0; i-- {
		for current.forward[i] != nil && current.forward[i].key < key {
			current = current.forward[i]
		}
	}

	current = current.forward[0]
	if current != nil && current.key == key {
		return current.value, true
	}
	return nil, false
}

func (sl *SkipList) randomLevel() int {
	level := 1
	for level < sl.maxLevel && (time.Now().UnixNano()%2 == 0) {
		level++
	}
	return level
}

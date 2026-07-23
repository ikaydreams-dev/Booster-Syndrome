package hashmap

import (
	"hash/fnv"
	"sync"
)

type Entry struct {
	Key   string
	Value interface{}
	Next  *Entry
}

type HashMap struct {
	buckets []*Entry
	size    int
	mu      sync.RWMutex
}

func NewHashMap(capacity int) *HashMap {
	return &HashMap{
		buckets: make([]*Entry, capacity),
		size:    0,
	}
}

func (hm *HashMap) hash(key string) uint32 {
	h := fnv.New32a()
	h.Write([]byte(key))
	return h.Sum32() % uint32(len(hm.buckets))
}

func (hm *HashMap) Put(key string, value interface{}) {
	hm.mu.Lock()
	defer hm.mu.Unlock()

	index := hm.hash(key)
	entry := hm.buckets[index]

	if entry == nil {
		hm.buckets[index] = &Entry{Key: key, Value: value, Next: nil}
		hm.size++
		return
	}

	for entry != nil {
		if entry.Key == key {
			entry.Value = value
			return
		}

		if entry.Next == nil {
			break
		}

		entry = entry.Next
	}

	entry.Next = &Entry{Key: key, Value: value, Next: nil}
	hm.size++
}

func (hm *HashMap) Get(key string) (interface{}, bool) {
	hm.mu.RLock()
	defer hm.mu.RUnlock()

	index := hm.hash(key)
	entry := hm.buckets[index]

	for entry != nil {
		if entry.Key == key {
			return entry.Value, true
		}
		entry = entry.Next
	}

	return nil, false
}

func (hm *HashMap) Remove(key string) bool {
	hm.mu.Lock()
	defer hm.mu.Unlock()

	index := hm.hash(key)
	entry := hm.buckets[index]

	if entry == nil {
		return false
	}

	if entry.Key == key {
		hm.buckets[index] = entry.Next
		hm.size--
		return true
	}

	for entry.Next != nil {
		if entry.Next.Key == key {
			entry.Next = entry.Next.Next
			hm.size--
			return true
		}
		entry = entry.Next
	}

	return false
}

func (hm *HashMap) Contains(key string) bool {
	_, exists := hm.Get(key)
	return exists
}

func (hm *HashMap) Size() int {
	hm.mu.RLock()
	defer hm.mu.RUnlock()
	return hm.size
}

func (hm *HashMap) Keys() []string {
	hm.mu.RLock()
	defer hm.mu.RUnlock()

	keys := make([]string, 0, hm.size)

	for _, entry := range hm.buckets {
		for entry != nil {
			keys = append(keys, entry.Key)
			entry = entry.Next
		}
	}

	return keys
}

func (hm *HashMap) Clear() {
	hm.mu.Lock()
	defer hm.mu.Unlock()

	hm.buckets = make([]*Entry, len(hm.buckets))
	hm.size = 0
}

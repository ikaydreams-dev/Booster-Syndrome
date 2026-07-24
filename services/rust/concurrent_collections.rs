use std::sync::{Arc, Mutex, RwLock};
use std::collections::{HashMap, VecDeque, BTreeMap};
use std::hash::Hash;
use std::thread;
use std::time::{Duration, Instant};

pub struct ConcurrentHashMap<K, V> {
    shards: Vec<RwLock<HashMap<K, V>>>,
    shard_count: usize,
}

impl<K: Hash + Eq, V> ConcurrentHashMap<K, V> {
    pub fn new(shard_count: usize) -> Self {
        let mut shards = Vec::with_capacity(shard_count);
        for _ in 0..shard_count {
            shards.push(RwLock::new(HashMap::new()));
        }

        ConcurrentHashMap {
            shards,
            shard_count,
        }
    }

    fn get_shard(&self, key: &K) -> usize {
        let mut hasher = std::collections::hash_map::DefaultHasher::new();
        key.hash(&mut hasher);
        use std::hash::Hasher;
        (hasher.finish() as usize) % self.shard_count
    }

    pub fn insert(&self, key: K, value: V) -> Option<V> {
        let shard_idx = self.get_shard(&key);
        let mut shard = self.shards[shard_idx].write().unwrap();
        shard.insert(key, value)
    }

    pub fn get(&self, key: &K) -> Option<V>
    where
        V: Clone,
    {
        let shard_idx = self.get_shard(key);
        let shard = self.shards[shard_idx].read().unwrap();
        shard.get(key).cloned()
    }

    pub fn remove(&self, key: &K) -> Option<V> {
        let shard_idx = self.get_shard(key);
        let mut shard = self.shards[shard_idx].write().unwrap();
        shard.remove(key)
    }

    pub fn contains_key(&self, key: &K) -> bool {
        let shard_idx = self.get_shard(key);
        let shard = self.shards[shard_idx].read().unwrap();
        shard.contains_key(key)
    }

    pub fn len(&self) -> usize {
        self.shards.iter()
            .map(|shard| shard.read().unwrap().len())
            .sum()
    }
}

pub struct ConcurrentQueue<T> {
    queue: Mutex<VecDeque<T>>,
}

impl<T> ConcurrentQueue<T> {
    pub fn new() -> Self {
        ConcurrentQueue {
            queue: Mutex::new(VecDeque::new()),
        }
    }

    pub fn enqueue(&self, item: T) {
        let mut queue = self.queue.lock().unwrap();
        queue.push_back(item);
    }

    pub fn dequeue(&self) -> Option<T> {
        let mut queue = self.queue.lock().unwrap();
        queue.pop_front()
    }

    pub fn is_empty(&self) -> bool {
        let queue = self.queue.lock().unwrap();
        queue.is_empty()
    }

    pub fn len(&self) -> usize {
        let queue = self.queue.lock().unwrap();
        queue.len()
    }
}

pub struct ConcurrentStack<T> {
    stack: Mutex<Vec<T>>,
}

impl<T> ConcurrentStack<T> {
    pub fn new() -> Self {
        ConcurrentStack {
            stack: Mutex::new(Vec::new()),
        }
    }

    pub fn push(&self, item: T) {
        let mut stack = self.stack.lock().unwrap();
        stack.push(item);
    }

    pub fn pop(&self) -> Option<T> {
        let mut stack = self.stack.lock().unwrap();
        stack.pop()
    }

    pub fn is_empty(&self) -> bool {
        let stack = self.stack.lock().unwrap();
        stack.is_empty()
    }

    pub fn len(&self) -> usize {
        let stack = self.stack.lock().unwrap();
        stack.len()
    }
}

pub struct ConcurrentSet<T> {
    map: ConcurrentHashMap<T, ()>,
}

impl<T: Hash + Eq> ConcurrentSet<T> {
    pub fn new(shard_count: usize) -> Self {
        ConcurrentSet {
            map: ConcurrentHashMap::new(shard_count),
        }
    }

    pub fn insert(&self, value: T) -> bool {
        self.map.insert(value, ()).is_none()
    }

    pub fn contains(&self, value: &T) -> bool {
        self.map.contains_key(value)
    }

    pub fn remove(&self, value: &T) -> bool {
        self.map.remove(value).is_some()
    }

    pub fn len(&self) -> usize {
        self.map.len()
    }
}

pub struct PriorityQueue<T> {
    heap: Mutex<BTreeMap<i32, Vec<T>>>,
}

impl<T> PriorityQueue<T> {
    pub fn new() -> Self {
        PriorityQueue {
            heap: Mutex::new(BTreeMap::new()),
        }
    }

    pub fn enqueue(&self, priority: i32, item: T) {
        let mut heap = self.heap.lock().unwrap();
        heap.entry(priority)
            .or_insert_with(Vec::new)
            .push(item);
    }

    pub fn dequeue(&self) -> Option<T> {
        let mut heap = self.heap.lock().unwrap();

        if let Some((&priority, _)) = heap.iter().next() {
            if let Some(items) = heap.get_mut(&priority) {
                let item = items.pop();
                if items.is_empty() {
                    heap.remove(&priority);
                }
                return item;
            }
        }
        None
    }

    pub fn is_empty(&self) -> bool {
        let heap = self.heap.lock().unwrap();
        heap.is_empty()
    }
}

pub struct RingBuffer<T> {
    buffer: Mutex<Vec<Option<T>>>,
    capacity: usize,
    read_pos: Mutex<usize>,
    write_pos: Mutex<usize>,
}

impl<T> RingBuffer<T> {
    pub fn new(capacity: usize) -> Self {
        RingBuffer {
            buffer: Mutex::new(vec![None; capacity]),
            capacity,
            read_pos: Mutex::new(0),
            write_pos: Mutex::new(0),
        }
    }

    pub fn write(&self, item: T) -> Result<(), T> {
        let mut buffer = self.buffer.lock().unwrap();
        let mut write_pos = self.write_pos.lock().unwrap();
        let read_pos = self.read_pos.lock().unwrap();

        let next_write = (*write_pos + 1) % self.capacity;
        if next_write == *read_pos {
            return Err(item);
        }

        buffer[*write_pos] = Some(item);
        *write_pos = next_write;
        Ok(())
    }

    pub fn read(&self) -> Option<T> {
        let mut buffer = self.buffer.lock().unwrap();
        let mut read_pos = self.read_pos.lock().unwrap();
        let write_pos = self.write_pos.lock().unwrap();

        if *read_pos == *write_pos {
            return None;
        }

        let item = buffer[*read_pos].take();
        *read_pos = (*read_pos + 1) % self.capacity;
        item
    }
}

pub struct LockFreeStack<T> {
    head: Arc<Mutex<Option<Box<Node<T>>>>>,
}

struct Node<T> {
    data: T,
    next: Option<Box<Node<T>>>,
}

impl<T> LockFreeStack<T> {
    pub fn new() -> Self {
        LockFreeStack {
            head: Arc::new(Mutex::new(None)),
        }
    }

    pub fn push(&self, data: T) {
        let mut head = self.head.lock().unwrap();
        let new_node = Box::new(Node {
            data,
            next: head.take(),
        });
        *head = Some(new_node);
    }

    pub fn pop(&self) -> Option<T> {
        let mut head = self.head.lock().unwrap();
        head.take().map(|node| {
            *head = node.next;
            node.data
        })
    }
}

pub struct ConcurrentBitSet {
    bits: Vec<RwLock<u64>>,
    size: usize,
}

impl ConcurrentBitSet {
    pub fn new(size: usize) -> Self {
        let word_count = (size + 63) / 64;
        let mut bits = Vec::with_capacity(word_count);
        for _ in 0..word_count {
            bits.push(RwLock::new(0));
        }

        ConcurrentBitSet { bits, size }
    }

    pub fn set(&self, index: usize) {
        if index >= self.size {
            return;
        }

        let word_idx = index / 64;
        let bit_idx = index % 64;
        let mut word = self.bits[word_idx].write().unwrap();
        *word |= 1u64 << bit_idx;
    }

    pub fn clear(&self, index: usize) {
        if index >= self.size {
            return;
        }

        let word_idx = index / 64;
        let bit_idx = index % 64;
        let mut word = self.bits[word_idx].write().unwrap();
        *word &= !(1u64 << bit_idx);
    }

    pub fn get(&self, index: usize) -> bool {
        if index >= self.size {
            return false;
        }

        let word_idx = index / 64;
        let bit_idx = index % 64;
        let word = self.bits[word_idx].read().unwrap();
        (*word & (1u64 << bit_idx)) != 0
    }
}

pub struct ConcurrentBloomFilter {
    bitset: ConcurrentBitSet,
    hash_count: usize,
}

impl ConcurrentBloomFilter {
    pub fn new(size: usize, hash_count: usize) -> Self {
        ConcurrentBloomFilter {
            bitset: ConcurrentBitSet::new(size),
            hash_count,
        }
    }

    pub fn add(&self, key: &str) {
        for i in 0..self.hash_count {
            let hash = self.hash(key, i);
            self.bitset.set(hash);
        }
    }

    pub fn contains(&self, key: &str) -> bool {
        for i in 0..self.hash_count {
            let hash = self.hash(key, i);
            if !self.bitset.get(hash) {
                return false;
            }
        }
        true
    }

    fn hash(&self, key: &str, seed: usize) -> usize {
        let mut hash: usize = seed;
        for byte in key.bytes() {
            hash = hash.wrapping_mul(31).wrapping_add(byte as usize);
        }
        hash % self.bitset.size
    }
}

pub struct TimeBasedCache<K, V> {
    cache: RwLock<HashMap<K, (V, Instant)>>,
    ttl: Duration,
}

impl<K: Hash + Eq, V: Clone> TimeBasedCache<K, V> {
    pub fn new(ttl: Duration) -> Self {
        TimeBasedCache {
            cache: RwLock::new(HashMap::new()),
            ttl,
        }
    }

    pub fn insert(&self, key: K, value: V) {
        let mut cache = self.cache.write().unwrap();
        cache.insert(key, (value, Instant::now()));
    }

    pub fn get(&self, key: &K) -> Option<V> {
        let cache = self.cache.read().unwrap();
        cache.get(key).and_then(|(value, timestamp)| {
            if timestamp.elapsed() < self.ttl {
                Some(value.clone())
            } else {
                None
            }
        })
    }

    pub fn cleanup(&self) {
        let mut cache = self.cache.write().unwrap();
        cache.retain(|_, (_, timestamp)| timestamp.elapsed() < self.ttl);
    }
}

pub struct CountMinSketch {
    table: Vec<Vec<RwLock<u64>>>,
    width: usize,
    depth: usize,
}

impl CountMinSketch {
    pub fn new(width: usize, depth: usize) -> Self {
        let mut table = Vec::with_capacity(depth);
        for _ in 0..depth {
            let mut row = Vec::with_capacity(width);
            for _ in 0..width {
                row.push(RwLock::new(0));
            }
            table.push(row);
        }

        CountMinSketch { table, width, depth }
    }

    pub fn increment(&self, key: &str) {
        for i in 0..self.depth {
            let hash = self.hash(key, i) % self.width;
            let mut cell = self.table[i][hash].write().unwrap();
            *cell += 1;
        }
    }

    pub fn estimate(&self, key: &str) -> u64 {
        let mut min = u64::MAX;
        for i in 0..self.depth {
            let hash = self.hash(key, i) % self.width;
            let cell = self.table[i][hash].read().unwrap();
            if *cell < min {
                min = *cell;
            }
        }
        min
    }

    fn hash(&self, key: &str, seed: usize) -> usize {
        let mut hash: usize = seed;
        for byte in key.bytes() {
            hash = hash.wrapping_mul(31).wrapping_add(byte as usize);
        }
        hash
    }
}

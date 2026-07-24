import threading
from collections import defaultdict, deque
from typing import Any, Optional, List, Tuple, Callable
import heapq
import bisect
import time

class TrieNode:
    def __init__(self):
        self.children = {}
        self.is_end_of_word = False
        self.value = None

class Trie:
    def __init__(self):
        self.root = TrieNode()
        self.lock = threading.RLock()

    def insert(self, key: str, value: Any = None):
        with self.lock:
            node = self.root
            for char in key:
                if char not in node.children:
                    node.children[char] = TrieNode()
                node = node.children[char]
            node.is_end_of_word = True
            node.value = value

    def search(self, key: str) -> Optional[Any]:
        with self.lock:
            node = self.root
            for char in key:
                if char not in node.children:
                    return None
                node = node.children[char]
            return node.value if node.is_end_of_word else None

    def starts_with(self, prefix: str) -> List[str]:
        with self.lock:
            node = self.root
            for char in prefix:
                if char not in node.children:
                    return []
                node = node.children[char]

            results = []
            self._collect_words(node, prefix, results)
            return results

    def _collect_words(self, node: TrieNode, prefix: str, results: List[str]):
        if node.is_end_of_word:
            results.append(prefix)

        for char, child in node.children.items():
            self._collect_words(child, prefix + char, results)

    def delete(self, key: str) -> bool:
        with self.lock:
            return self._delete_helper(self.root, key, 0)

    def _delete_helper(self, node: TrieNode, key: str, depth: int) -> bool:
        if depth == len(key):
            if not node.is_end_of_word:
                return False
            node.is_end_of_word = False
            return len(node.children) == 0

        char = key[depth]
        if char not in node.children:
            return False

        should_delete = self._delete_helper(node.children[char], key, depth + 1)

        if should_delete:
            del node.children[char]
            return len(node.children) == 0 and not node.is_end_of_word

        return False

class SuffixArray:
    def __init__(self, text: str):
        self.text = text
        self.n = len(text)
        self.suffix_array = self._build_suffix_array()
        self.lcp = self._build_lcp()

    def _build_suffix_array(self) -> List[int]:
        suffixes = [(self.text[i:], i) for i in range(self.n)]
        suffixes.sort()
        return [suffix[1] for suffix in suffixes]

    def _build_lcp(self) -> List[int]:
        rank = [0] * self.n
        for i, suffix_idx in enumerate(self.suffix_array):
            rank[suffix_idx] = i

        lcp = [0] * self.n
        h = 0

        for i in range(self.n):
            if rank[i] > 0:
                j = self.suffix_array[rank[i] - 1]
                while i + h < self.n and j + h < self.n and self.text[i + h] == self.text[j + h]:
                    h += 1
                lcp[rank[i]] = h
                if h > 0:
                    h -= 1

        return lcp

    def search(self, pattern: str) -> List[int]:
        left = bisect.bisect_left(self.suffix_array, pattern, key=lambda i: self.text[i:i+len(pattern)])
        right = bisect.bisect_right(self.suffix_array, pattern, key=lambda i: self.text[i:i+len(pattern)])

        results = []
        for i in range(left, right):
            if self.text[self.suffix_array[i]:].startswith(pattern):
                results.append(self.suffix_array[i])
        return results

class IntervalTree:
    def __init__(self):
        self.intervals = []
        self.lock = threading.RLock()

    def insert(self, start: int, end: int, value: Any):
        with self.lock:
            self.intervals.append((start, end, value))
            self.intervals.sort()

    def query(self, point: int) -> List[Tuple[int, int, Any]]:
        with self.lock:
            return [(s, e, v) for s, e, v in self.intervals if s <= point <= e]

    def query_range(self, start: int, end: int) -> List[Tuple[int, int, Any]]:
        with self.lock:
            return [(s, e, v) for s, e, v in self.intervals if not (e < start or s > end)]

class SegmentTree:
    def __init__(self, arr: List[int], merge_fn: Callable[[int, int], int]):
        self.n = len(arr)
        self.tree = [0] * (4 * self.n)
        self.merge_fn = merge_fn
        self._build(arr, 0, 0, self.n - 1)

    def _build(self, arr: List[int], node: int, start: int, end: int):
        if start == end:
            self.tree[node] = arr[start]
        else:
            mid = (start + end) // 2
            self._build(arr, 2 * node + 1, start, mid)
            self._build(arr, 2 * node + 2, mid + 1, end)
            self.tree[node] = self.merge_fn(self.tree[2 * node + 1], self.tree[2 * node + 2])

    def query(self, left: int, right: int) -> int:
        return self._query(0, 0, self.n - 1, left, right)

    def _query(self, node: int, start: int, end: int, left: int, right: int) -> int:
        if right < start or left > end:
            return 0

        if left <= start and end <= right:
            return self.tree[node]

        mid = (start + end) // 2
        left_val = self._query(2 * node + 1, start, mid, left, right)
        right_val = self._query(2 * node + 2, mid + 1, end, left, right)
        return self.merge_fn(left_val, right_val)

    def update(self, index: int, value: int):
        self._update(0, 0, self.n - 1, index, value)

    def _update(self, node: int, start: int, end: int, index: int, value: int):
        if start == end:
            self.tree[node] = value
        else:
            mid = (start + end) // 2
            if index <= mid:
                self._update(2 * node + 1, start, mid, index, value)
            else:
                self._update(2 * node + 2, mid + 1, end, index, value)
            self.tree[node] = self.merge_fn(self.tree[2 * node + 1], self.tree[2 * node + 2])

class FenwickTree:
    def __init__(self, n: int):
        self.n = n
        self.tree = [0] * (n + 1)

    def update(self, i: int, delta: int):
        i += 1
        while i <= self.n:
            self.tree[i] += delta
            i += i & (-i)

    def query(self, i: int) -> int:
        i += 1
        result = 0
        while i > 0:
            result += self.tree[i]
            i -= i & (-i)
        return result

    def range_query(self, left: int, right: int) -> int:
        return self.query(right) - (self.query(left - 1) if left > 0 else 0)

class DisjointSet:
    def __init__(self, n: int):
        self.parent = list(range(n))
        self.rank = [0] * n

    def find(self, x: int) -> int:
        if self.parent[x] != x:
            self.parent[x] = self.find(self.parent[x])
        return self.parent[x]

    def union(self, x: int, y: int):
        px, py = self.find(x), self.find(y)
        if px == py:
            return

        if self.rank[px] < self.rank[py]:
            px, py = py, px

        self.parent[py] = px
        if self.rank[px] == self.rank[py]:
            self.rank[px] += 1

    def connected(self, x: int, y: int) -> bool:
        return self.find(x) == self.find(y)

class LRUCache:
    def __init__(self, capacity: int):
        self.capacity = capacity
        self.cache = {}
        self.order = deque()
        self.lock = threading.RLock()

    def get(self, key: str) -> Optional[Any]:
        with self.lock:
            if key in self.cache:
                self.order.remove(key)
                self.order.append(key)
                return self.cache[key]
            return None

    def put(self, key: str, value: Any):
        with self.lock:
            if key in self.cache:
                self.order.remove(key)
            elif len(self.cache) >= self.capacity:
                oldest = self.order.popleft()
                del self.cache[oldest]

            self.cache[key] = value
            self.order.append(key)

class LFUCache:
    def __init__(self, capacity: int):
        self.capacity = capacity
        self.cache = {}
        self.freq = defaultdict(int)
        self.freq_list = defaultdict(deque)
        self.min_freq = 0
        self.lock = threading.RLock()

    def get(self, key: str) -> Optional[Any]:
        with self.lock:
            if key not in self.cache:
                return None

            freq = self.freq[key]
            self.freq_list[freq].remove(key)
            if not self.freq_list[freq] and freq == self.min_freq:
                self.min_freq += 1

            self.freq[key] += 1
            self.freq_list[self.freq[key]].append(key)

            return self.cache[key]

    def put(self, key: str, value: Any):
        with self.lock:
            if self.capacity <= 0:
                return

            if key in self.cache:
                self.cache[key] = value
                self.get(key)
                return

            if len(self.cache) >= self.capacity:
                evict_key = self.freq_list[self.min_freq].popleft()
                del self.cache[evict_key]
                del self.freq[evict_key]

            self.cache[key] = value
            self.freq[key] = 1
            self.freq_list[1].append(key)
            self.min_freq = 1

class BloomFilter:
    def __init__(self, size: int, hash_count: int):
        self.size = size
        self.hash_count = hash_count
        self.bit_array = [False] * size

    def add(self, item: str):
        for i in range(self.hash_count):
            index = self._hash(item, i) % self.size
            self.bit_array[index] = True

    def contains(self, item: str) -> bool:
        for i in range(self.hash_count):
            index = self._hash(item, i) % self.size
            if not self.bit_array[index]:
                return False
        return True

    def _hash(self, item: str, seed: int) -> int:
        h = seed
        for char in item:
            h = (h * 31 + ord(char)) & 0xFFFFFFFF
        return h

class SkipList:
    class Node:
        def __init__(self, key, value, level):
            self.key = key
            self.value = value
            self.forward = [None] * (level + 1)

    def __init__(self, max_level: int = 16):
        self.max_level = max_level
        self.level = 0
        self.header = self.Node(None, None, max_level)

    def insert(self, key: str, value: Any):
        update = [None] * (self.max_level + 1)
        current = self.header

        for i in range(self.level, -1, -1):
            while current.forward[i] and current.forward[i].key < key:
                current = current.forward[i]
            update[i] = current

        level = self._random_level()
        if level > self.level:
            for i in range(self.level + 1, level + 1):
                update[i] = self.header
            self.level = level

        new_node = self.Node(key, value, level)
        for i in range(level + 1):
            new_node.forward[i] = update[i].forward[i]
            update[i].forward[i] = new_node

    def search(self, key: str) -> Optional[Any]:
        current = self.header
        for i in range(self.level, -1, -1):
            while current.forward[i] and current.forward[i].key < key:
                current = current.forward[i]

        current = current.forward[0]
        if current and current.key == key:
            return current.value
        return None

    def _random_level(self) -> int:
        level = 0
        while level < self.max_level and int(time.time() * 1000000) % 2 == 0:
            level += 1
        return level

class RBTree:
    RED = True
    BLACK = False

    class Node:
        def __init__(self, key, value):
            self.key = key
            self.value = value
            self.left = None
            self.right = None
            self.color = RBTree.RED

    def __init__(self):
        self.root = None

    def insert(self, key: str, value: Any):
        self.root = self._insert(self.root, key, value)
        self.root.color = self.BLACK

    def _insert(self, node, key, value):
        if node is None:
            return self.Node(key, value)

        if key < node.key:
            node.left = self._insert(node.left, key, value)
        elif key > node.key:
            node.right = self._insert(node.right, key, value)
        else:
            node.value = value

        if self._is_red(node.right) and not self._is_red(node.left):
            node = self._rotate_left(node)
        if self._is_red(node.left) and self._is_red(node.left.left):
            node = self._rotate_right(node)
        if self._is_red(node.left) and self._is_red(node.right):
            self._flip_colors(node)

        return node

    def _is_red(self, node) -> bool:
        if node is None:
            return False
        return node.color == self.RED

    def _rotate_left(self, node):
        x = node.right
        node.right = x.left
        x.left = node
        x.color = node.color
        node.color = self.RED
        return x

    def _rotate_right(self, node):
        x = node.left
        node.left = x.right
        x.right = node
        x.color = node.color
        node.color = self.RED
        return x

    def _flip_colors(self, node):
        node.color = self.RED
        node.left.color = self.BLACK
        node.right.color = self.BLACK

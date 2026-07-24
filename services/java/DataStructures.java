import java.util.*;
import java.util.concurrent.*;
import java.util.function.*;

public class DataStructures {

    public static class Trie {
        private class TrieNode {
            Map<Character, TrieNode> children = new HashMap<>();
            boolean isEndOfWord = false;
            Object value = null;
        }

        private TrieNode root = new TrieNode();

        public void insert(String key, Object value) {
            TrieNode current = root;
            for (char ch : key.toCharArray()) {
                current = current.children.computeIfAbsent(ch, c -> new TrieNode());
            }
            current.isEndOfWord = true;
            current.value = value;
        }

        public Object search(String key) {
            TrieNode current = root;
            for (char ch : key.toCharArray()) {
                current = current.children.get(ch);
                if (current == null) return null;
            }
            return current.isEndOfWord ? current.value : null;
        }

        public boolean startsWith(String prefix) {
            TrieNode current = root;
            for (char ch : prefix.toCharArray()) {
                current = current.children.get(ch);
                if (current == null) return false;
            }
            return true;
        }

        public void delete(String key) {
            delete(root, key, 0);
        }

        private boolean delete(TrieNode current, String key, int index) {
            if (index == key.length()) {
                if (!current.isEndOfWord) return false;
                current.isEndOfWord = false;
                return current.children.isEmpty();
            }

            char ch = key.charAt(index);
            TrieNode node = current.children.get(ch);
            if (node == null) return false;

            boolean shouldDeleteCurrentNode = delete(node, key, index + 1);

            if (shouldDeleteCurrentNode) {
                current.children.remove(ch);
                return current.children.isEmpty() && !current.isEndOfWord;
            }

            return false;
        }
    }

    public static class LRUCache<K, V> {
        private class Node {
            K key;
            V value;
            Node prev, next;

            Node(K key, V value) {
                this.key = key;
                this.value = value;
            }
        }

        private final int capacity;
        private final Map<K, Node> cache = new HashMap<>();
        private final Node head = new Node(null, null);
        private final Node tail = new Node(null, null);

        public LRUCache(int capacity) {
            this.capacity = capacity;
            head.next = tail;
            tail.prev = head;
        }

        public V get(K key) {
            Node node = cache.get(key);
            if (node == null) return null;

            moveToHead(node);
            return node.value;
        }

        public void put(K key, V value) {
            Node node = cache.get(key);

            if (node != null) {
                node.value = value;
                moveToHead(node);
            } else {
                Node newNode = new Node(key, value);
                cache.put(key, newNode);
                addToHead(newNode);

                if (cache.size() > capacity) {
                    Node removed = removeTail();
                    cache.remove(removed.key);
                }
            }
        }

        private void addToHead(Node node) {
            node.prev = head;
            node.next = head.next;
            head.next.prev = node;
            head.next = node;
        }

        private void removeNode(Node node) {
            node.prev.next = node.next;
            node.next.prev = node.prev;
        }

        private void moveToHead(Node node) {
            removeNode(node);
            addToHead(node);
        }

        private Node removeTail() {
            Node node = tail.prev;
            removeNode(node);
            return node;
        }
    }

    public static class BloomFilter {
        private BitSet bitSet;
        private int size;
        private int hashFunctions;

        public BloomFilter(int size, int hashFunctions) {
            this.size = size;
            this.hashFunctions = hashFunctions;
            this.bitSet = new BitSet(size);
        }

        public void add(String item) {
            for (int i = 0; i < hashFunctions; i++) {
                int hash = hash(item, i);
                bitSet.set(hash);
            }
        }

        public boolean contains(String item) {
            for (int i = 0; i < hashFunctions; i++) {
                int hash = hash(item, i);
                if (!bitSet.get(hash)) return false;
            }
            return true;
        }

        private int hash(String item, int seed) {
            int h = seed;
            for (char c : item.toCharArray()) {
                h = 31 * h + c;
            }
            return Math.abs(h % size);
        }
    }

    public static class DisjointSet {
        private int[] parent;
        private int[] rank;

        public DisjointSet(int n) {
            parent = new int[n];
            rank = new int[n];
            for (int i = 0; i < n; i++) {
                parent[i] = i;
            }
        }

        public int find(int x) {
            if (parent[x] != x) {
                parent[x] = find(parent[x]);
            }
            return parent[x];
        }

        public void union(int x, int y) {
            int px = find(x);
            int py = find(y);

            if (px == py) return;

            if (rank[px] < rank[py]) {
                parent[px] = py;
            } else if (rank[px] > rank[py]) {
                parent[py] = px;
            } else {
                parent[py] = px;
                rank[px]++;
            }
        }

        public boolean connected(int x, int y) {
            return find(x) == find(y);
        }
    }

    public static class SegmentTree {
        private int[] tree;
        private int n;
        private BiFunction<Integer, Integer, Integer> mergeFunction;

        public SegmentTree(int[] arr, BiFunction<Integer, Integer, Integer> mergeFunction) {
            this.n = arr.length;
            this.mergeFunction = mergeFunction;
            this.tree = new int[4 * n];
            build(arr, 0, 0, n - 1);
        }

        private void build(int[] arr, int node, int start, int end) {
            if (start == end) {
                tree[node] = arr[start];
            } else {
                int mid = (start + end) / 2;
                build(arr, 2 * node + 1, start, mid);
                build(arr, 2 * node + 2, mid + 1, end);
                tree[node] = mergeFunction.apply(tree[2 * node + 1], tree[2 * node + 2]);
            }
        }

        public int query(int left, int right) {
            return query(0, 0, n - 1, left, right);
        }

        private int query(int node, int start, int end, int left, int right) {
            if (right < start || left > end) return 0;

            if (left <= start && end <= right) {
                return tree[node];
            }

            int mid = (start + end) / 2;
            int leftVal = query(2 * node + 1, start, mid, left, right);
            int rightVal = query(2 * node + 2, mid + 1, end, left, right);
            return mergeFunction.apply(leftVal, rightVal);
        }

        public void update(int index, int value) {
            update(0, 0, n - 1, index, value);
        }

        private void update(int node, int start, int end, int index, int value) {
            if (start == end) {
                tree[node] = value;
            } else {
                int mid = (start + end) / 2;
                if (index <= mid) {
                    update(2 * node + 1, start, mid, index, value);
                } else {
                    update(2 * node + 2, mid + 1, end, index, value);
                }
                tree[node] = mergeFunction.apply(tree[2 * node + 1], tree[2 * node + 2]);
            }
        }
    }

    public static class FenwickTree {
        private int[] tree;
        private int n;

        public FenwickTree(int n) {
            this.n = n;
            this.tree = new int[n + 1];
        }

        public void update(int i, int delta) {
            i++;
            while (i <= n) {
                tree[i] += delta;
                i += i & (-i);
            }
        }

        public int query(int i) {
            i++;
            int sum = 0;
            while (i > 0) {
                sum += tree[i];
                i -= i & (-i);
            }
            return sum;
        }

        public int rangeQuery(int left, int right) {
            return query(right) - (left > 0 ? query(left - 1) : 0);
        }
    }

    public static class SkipList<K extends Comparable<K>, V> {
        private class Node {
            K key;
            V value;
            Node[] forward;

            @SuppressWarnings("unchecked")
            Node(K key, V value, int level) {
                this.key = key;
                this.value = value;
                this.forward = (Node[]) new SkipList.Node[level + 1];
            }
        }

        private static final int MAX_LEVEL = 16;
        private Node head;
        private int level;
        private Random random;

        @SuppressWarnings("unchecked")
        public SkipList() {
            this.head = new Node(null, null, MAX_LEVEL);
            this.level = 0;
            this.random = new Random();
        }

        private int randomLevel() {
            int lvl = 0;
            while (lvl < MAX_LEVEL && random.nextBoolean()) {
                lvl++;
            }
            return lvl;
        }

        public void insert(K key, V value) {
            @SuppressWarnings("unchecked")
            Node[] update = (Node[]) new SkipList.Node[MAX_LEVEL + 1];
            Node current = head;

            for (int i = level; i >= 0; i--) {
                while (current.forward[i] != null && current.forward[i].key.compareTo(key) < 0) {
                    current = current.forward[i];
                }
                update[i] = current;
            }

            int newLevel = randomLevel();
            if (newLevel > level) {
                for (int i = level + 1; i <= newLevel; i++) {
                    update[i] = head;
                }
                level = newLevel;
            }

            Node newNode = new Node(key, value, newLevel);
            for (int i = 0; i <= newLevel; i++) {
                newNode.forward[i] = update[i].forward[i];
                update[i].forward[i] = newNode;
            }
        }

        public V search(K key) {
            Node current = head;
            for (int i = level; i >= 0; i--) {
                while (current.forward[i] != null && current.forward[i].key.compareTo(key) < 0) {
                    current = current.forward[i];
                }
            }

            current = current.forward[0];
            if (current != null && current.key.equals(key)) {
                return current.value;
            }
            return null;
        }
    }

    public static class IntervalTree {
        private class Node {
            int start, end, max;
            Object data;
            Node left, right;

            Node(int start, int end, Object data) {
                this.start = start;
                this.end = end;
                this.max = end;
                this.data = data;
            }
        }

        private Node root;

        public void insert(int start, int end, Object data) {
            root = insert(root, start, end, data);
        }

        private Node insert(Node node, int start, int end, Object data) {
            if (node == null) {
                return new Node(start, end, data);
            }

            if (start < node.start) {
                node.left = insert(node.left, start, end, data);
            } else {
                node.right = insert(node.right, start, end, data);
            }

            node.max = Math.max(node.max, end);
            return node;
        }

        public List<Object> query(int point) {
            List<Object> result = new ArrayList<>();
            query(root, point, result);
            return result;
        }

        private void query(Node node, int point, List<Object> result) {
            if (node == null) return;

            if (node.start <= point && point <= node.end) {
                result.add(node.data);
            }

            if (node.left != null && node.left.max >= point) {
                query(node.left, point, result);
            }

            query(node.right, point, result);
        }
    }
}

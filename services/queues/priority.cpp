#include <vector>
#include <functional>
#include <stdexcept>

template<typename T, typename Compare = std::less<T>>
class PriorityQueue {
private:
    std::vector<T> heap;
    Compare comp;

    void heapifyUp(size_t index) {
        while (index > 0) {
            size_t parent = (index - 1) / 2;
            if (comp(heap[index], heap[parent])) {
                std::swap(heap[index], heap[parent]);
                index = parent;
            } else {
                break;
            }
        }
    }

    void heapifyDown(size_t index) {
        size_t size = heap.size();

        while (true) {
            size_t smallest = index;
            size_t left = 2 * index + 1;
            size_t right = 2 * index + 2;

            if (left < size && comp(heap[left], heap[smallest])) {
                smallest = left;
            }

            if (right < size && comp(heap[right], heap[smallest])) {
                smallest = right;
            }

            if (smallest != index) {
                std::swap(heap[index], heap[smallest]);
                index = smallest;
            } else {
                break;
            }
        }
    }

public:
    PriorityQueue() = default;

    void push(const T& value) {
        heap.push_back(value);
        heapifyUp(heap.size() - 1);
    }

    void push(T&& value) {
        heap.push_back(std::move(value));
        heapifyUp(heap.size() - 1);
    }

    T pop() {
        if (heap.empty()) {
            throw std::runtime_error("Queue is empty");
        }

        T result = heap[0];
        heap[0] = heap.back();
        heap.pop_back();

        if (!heap.empty()) {
            heapifyDown(0);
        }

        return result;
    }

    const T& top() const {
        if (heap.empty()) {
            throw std::runtime_error("Queue is empty");
        }
        return heap[0];
    }

    bool empty() const {
        return heap.empty();
    }

    size_t size() const {
        return heap.size();
    }

    void clear() {
        heap.clear();
    }
};

template<typename T>
class Deque {
private:
    struct Node {
        T data;
        Node* prev;
        Node* next;

        Node(const T& d) : data(d), prev(nullptr), next(nullptr) {}
    };

    Node* head;
    Node* tail;
    size_t count;

public:
    Deque() : head(nullptr), tail(nullptr), count(0) {}

    ~Deque() {
        clear();
    }

    void pushFront(const T& value) {
        Node* node = new Node(value);

        if (empty()) {
            head = tail = node;
        } else {
            node->next = head;
            head->prev = node;
            head = node;
        }

        count++;
    }

    void pushBack(const T& value) {
        Node* node = new Node(value);

        if (empty()) {
            head = tail = node;
        } else {
            node->prev = tail;
            tail->next = node;
            tail = node;
        }

        count++;
    }

    T popFront() {
        if (empty()) {
            throw std::runtime_error("Deque is empty");
        }

        Node* node = head;
        T value = node->data;

        head = head->next;
        if (head) {
            head->prev = nullptr;
        } else {
            tail = nullptr;
        }

        delete node;
        count--;

        return value;
    }

    T popBack() {
        if (empty()) {
            throw std::runtime_error("Deque is empty");
        }

        Node* node = tail;
        T value = node->data;

        tail = tail->prev;
        if (tail) {
            tail->next = nullptr;
        } else {
            head = nullptr;
        }

        delete node;
        count--;

        return value;
    }

    const T& front() const {
        if (empty()) {
            throw std::runtime_error("Deque is empty");
        }
        return head->data;
    }

    const T& back() const {
        if (empty()) {
            throw std::runtime_error("Deque is empty");
        }
        return tail->data;
    }

    bool empty() const {
        return count == 0;
    }

    size_t size() const {
        return count;
    }

    void clear() {
        while (!empty()) {
            popFront();
        }
    }
};

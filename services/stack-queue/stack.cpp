#include <iostream>
#include <vector>
#include <stdexcept>

template<typename T>
class Stack {
private:
    std::vector<T> items;

public:
    void push(T item) {
        items.push_back(item);
    }

    T pop() {
        if (isEmpty()) {
            throw std::runtime_error("Stack is empty");
        }

        T item = items.back();
        items.pop_back();
        return item;
    }

    T peek() const {
        if (isEmpty()) {
            throw std::runtime_error("Stack is empty");
        }

        return items.back();
    }

    bool isEmpty() const {
        return items.empty();
    }

    size_t size() const {
        return items.size();
    }

    void clear() {
        items.clear();
    }
};

template<typename T>
class Queue {
private:
    std::vector<T> items;
    size_t front_index;

public:
    Queue() : front_index(0) {}

    void enqueue(T item) {
        items.push_back(item);
    }

    T dequeue() {
        if (isEmpty()) {
            throw std::runtime_error("Queue is empty");
        }

        return items[front_index++];
    }

    T front() const {
        if (isEmpty()) {
            throw std::runtime_error("Queue is empty");
        }

        return items[front_index];
    }

    bool isEmpty() const {
        return front_index >= items.size();
    }

    size_t size() const {
        return items.size() - front_index;
    }

    void clear() {
        items.clear();
        front_index = 0;
    }
};

template<typename T>
class PriorityQueue {
private:
    struct Element {
        T value;
        int priority;

        bool operator<(const Element& other) const {
            return priority < other.priority;
        }
    };

    std::vector<Element> heap;

    void heapifyUp(size_t index) {
        while (index > 0) {
            size_t parent = (index - 1) / 2;

            if (heap[index] < heap[parent]) break;

            std::swap(heap[index], heap[parent]);
            index = parent;
        }
    }

    void heapifyDown(size_t index) {
        size_t size = heap.size();

        while (true) {
            size_t largest = index;
            size_t left = 2 * index + 1;
            size_t right = 2 * index + 2;

            if (left < size && heap[largest] < heap[left]) {
                largest = left;
            }

            if (right < size && heap[largest] < heap[right]) {
                largest = right;
            }

            if (largest == index) break;

            std::swap(heap[index], heap[largest]);
            index = largest;
        }
    }

public:
    void insert(T value, int priority) {
        heap.push_back({value, priority});
        heapifyUp(heap.size() - 1);
    }

    T extractMax() {
        if (heap.empty()) {
            throw std::runtime_error("Priority queue is empty");
        }

        T value = heap[0].value;
        heap[0] = heap.back();
        heap.pop_back();

        if (!heap.empty()) {
            heapifyDown(0);
        }

        return value;
    }

    bool isEmpty() const {
        return heap.empty();
    }

    size_t size() const {
        return heap.size();
    }
};

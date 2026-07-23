#include <cstddef>
#include <utility>

template<typename T>
class UniquePtr {
private:
    T* ptr;

public:
    UniquePtr() : ptr(nullptr) {}

    explicit UniquePtr(T* p) : ptr(p) {}

    ~UniquePtr() {
        delete ptr;
    }

    UniquePtr(const UniquePtr&) = delete;
    UniquePtr& operator=(const UniquePtr&) = delete;

    UniquePtr(UniquePtr&& other) noexcept : ptr(other.ptr) {
        other.ptr = nullptr;
    }

    UniquePtr& operator=(UniquePtr&& other) noexcept {
        if (this != &other) {
            delete ptr;
            ptr = other.ptr;
            other.ptr = nullptr;
        }
        return *this;
    }

    T& operator*() const {
        return *ptr;
    }

    T* operator->() const {
        return ptr;
    }

    T* get() const {
        return ptr;
    }

    T* release() {
        T* temp = ptr;
        ptr = nullptr;
        return temp;
    }

    void reset(T* p = nullptr) {
        delete ptr;
        ptr = p;
    }

    explicit operator bool() const {
        return ptr != nullptr;
    }
};

template<typename T>
class SharedPtr {
private:
    T* ptr;
    size_t* refCount;

    void addRef() {
        if (refCount) {
            ++(*refCount);
        }
    }

    void release() {
        if (refCount && --(*refCount) == 0) {
            delete ptr;
            delete refCount;
        }
    }

public:
    SharedPtr() : ptr(nullptr), refCount(nullptr) {}

    explicit SharedPtr(T* p) : ptr(p), refCount(p ? new size_t(1) : nullptr) {}

    SharedPtr(const SharedPtr& other) : ptr(other.ptr), refCount(other.refCount) {
        addRef();
    }

    SharedPtr(SharedPtr&& other) noexcept : ptr(other.ptr), refCount(other.refCount) {
        other.ptr = nullptr;
        other.refCount = nullptr;
    }

    ~SharedPtr() {
        release();
    }

    SharedPtr& operator=(const SharedPtr& other) {
        if (this != &other) {
            release();
            ptr = other.ptr;
            refCount = other.refCount;
            addRef();
        }
        return *this;
    }

    SharedPtr& operator=(SharedPtr&& other) noexcept {
        if (this != &other) {
            release();
            ptr = other.ptr;
            refCount = other.refCount;
            other.ptr = nullptr;
            other.refCount = nullptr;
        }
        return *this;
    }

    T& operator*() const {
        return *ptr;
    }

    T* operator->() const {
        return ptr;
    }

    T* get() const {
        return ptr;
    }

    size_t useCount() const {
        return refCount ? *refCount : 0;
    }

    explicit operator bool() const {
        return ptr != nullptr;
    }
};

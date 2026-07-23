#include <cstdlib>
#include <cstring>
#include <new>

class MemoryPool {
private:
    struct Block {
        Block* next;
    };

    void* pool;
    Block* freeList;
    size_t blockSize;
    size_t poolSize;

public:
    MemoryPool(size_t blockSize, size_t numBlocks)
        : blockSize(blockSize < sizeof(Block*) ? sizeof(Block*) : blockSize),
          poolSize(this->blockSize * numBlocks) {

        pool = std::malloc(poolSize);
        if (!pool) {
            throw std::bad_alloc();
        }

        freeList = nullptr;

        char* current = static_cast<char*>(pool);
        for (size_t i = 0; i < numBlocks; ++i) {
            Block* block = reinterpret_cast<Block*>(current);
            block->next = freeList;
            freeList = block;
            current += this->blockSize;
        }
    }

    ~MemoryPool() {
        std::free(pool);
    }

    void* allocate() {
        if (!freeList) {
            return nullptr;
        }

        Block* block = freeList;
        freeList = block->next;

        return block;
    }

    void deallocate(void* ptr) {
        if (!ptr) return;

        Block* block = static_cast<Block*>(ptr);
        block->next = freeList;
        freeList = block;
    }

    size_t getBlockSize() const {
        return blockSize;
    }

    bool owns(void* ptr) const {
        char* p = static_cast<char*>(ptr);
        char* poolStart = static_cast<char*>(pool);
        return p >= poolStart && p < poolStart + poolSize;
    }
};

class StackAllocator {
private:
    void* buffer;
    size_t size;
    size_t offset;

public:
    StackAllocator(size_t size) : size(size), offset(0) {
        buffer = std::malloc(size);
        if (!buffer) {
            throw std::bad_alloc();
        }
    }

    ~StackAllocator() {
        std::free(buffer);
    }

    void* allocate(size_t bytes, size_t alignment = alignof(std::max_align_t)) {
        size_t padding = (alignment - (offset % alignment)) % alignment;
        size_t totalSize = padding + bytes;

        if (offset + totalSize > size) {
            return nullptr;
        }

        void* ptr = static_cast<char*>(buffer) + offset + padding;
        offset += totalSize;

        return ptr;
    }

    void reset() {
        offset = 0;
    }

    size_t getUsed() const {
        return offset;
    }

    size_t getRemaining() const {
        return size - offset;
    }
};

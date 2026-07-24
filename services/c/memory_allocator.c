#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <stdbool.h>

#define HEAP_SIZE 1024 * 1024
#define MIN_BLOCK_SIZE 16
#define ALIGNMENT 8

typedef struct Block {
    size_t size;
    bool is_free;
    struct Block* next;
    struct Block* prev;
} Block;

typedef struct {
    Block* free_list;
    void* heap_start;
    void* heap_end;
    size_t total_size;
    size_t used_size;
} Allocator;

Allocator* allocator_create(size_t size) {
    Allocator* alloc = (Allocator*)malloc(sizeof(Allocator));
    if (!alloc) return NULL;

    alloc->heap_start = malloc(size);
    if (!alloc->heap_start) {
        free(alloc);
        return NULL;
    }

    alloc->heap_end = (char*)alloc->heap_start + size;
    alloc->total_size = size;
    alloc->used_size = 0;

    Block* initial_block = (Block*)alloc->heap_start;
    initial_block->size = size - sizeof(Block);
    initial_block->is_free = true;
    initial_block->next = NULL;
    initial_block->prev = NULL;

    alloc->free_list = initial_block;

    return alloc;
}

void allocator_destroy(Allocator* alloc) {
    if (alloc) {
        free(alloc->heap_start);
        free(alloc);
    }
}

static size_t align_size(size_t size) {
    return (size + ALIGNMENT - 1) & ~(ALIGNMENT - 1);
}

static Block* find_free_block(Allocator* alloc, size_t size) {
    Block* current = alloc->free_list;

    while (current) {
        if (current->is_free && current->size >= size) {
            return current;
        }
        current = current->next;
    }

    return NULL;
}

static void split_block(Block* block, size_t size) {
    if (block->size >= size + sizeof(Block) + MIN_BLOCK_SIZE) {
        Block* new_block = (Block*)((char*)block + sizeof(Block) + size);
        new_block->size = block->size - size - sizeof(Block);
        new_block->is_free = true;
        new_block->next = block->next;
        new_block->prev = block;

        if (block->next) {
            block->next->prev = new_block;
        }

        block->next = new_block;
        block->size = size;
    }
}

static void merge_blocks(Allocator* alloc) {
    Block* current = alloc->free_list;

    while (current && current->next) {
        if (current->is_free && current->next->is_free) {
            current->size += sizeof(Block) + current->next->size;
            current->next = current->next->next;

            if (current->next) {
                current->next->prev = current;
            }
        } else {
            current = current->next;
        }
    }
}

void* allocator_alloc(Allocator* alloc, size_t size) {
    if (!alloc || size == 0) return NULL;

    size = align_size(size);
    Block* block = find_free_block(alloc, size);

    if (!block) return NULL;

    split_block(block, size);
    block->is_free = false;
    alloc->used_size += size + sizeof(Block);

    return (char*)block + sizeof(Block);
}

void allocator_free(Allocator* alloc, void* ptr) {
    if (!alloc || !ptr) return;

    Block* block = (Block*)((char*)ptr - sizeof(Block));
    block->is_free = true;
    alloc->used_size -= block->size + sizeof(Block);

    merge_blocks(alloc);
}

void* allocator_realloc(Allocator* alloc, void* ptr, size_t new_size) {
    if (!alloc) return NULL;
    if (!ptr) return allocator_alloc(alloc, new_size);
    if (new_size == 0) {
        allocator_free(alloc, ptr);
        return NULL;
    }

    Block* block = (Block*)((char*)ptr - sizeof(Block));
    new_size = align_size(new_size);

    if (block->size >= new_size) {
        split_block(block, new_size);
        return ptr;
    }

    void* new_ptr = allocator_alloc(alloc, new_size);
    if (!new_ptr) return NULL;

    memcpy(new_ptr, ptr, block->size);
    allocator_free(alloc, ptr);

    return new_ptr;
}

typedef struct PoolBlock {
    struct PoolBlock* next;
} PoolBlock;

typedef struct {
    void* pool;
    size_t block_size;
    size_t block_count;
    PoolBlock* free_list;
} PoolAllocator;

PoolAllocator* pool_allocator_create(size_t block_size, size_t block_count) {
    PoolAllocator* pool = (PoolAllocator*)malloc(sizeof(PoolAllocator));
    if (!pool) return NULL;

    pool->block_size = align_size(block_size);
    pool->block_count = block_count;

    size_t pool_size = pool->block_size * block_count;
    pool->pool = malloc(pool_size);
    if (!pool->pool) {
        free(pool);
        return NULL;
    }

    pool->free_list = NULL;
    for (size_t i = 0; i < block_count; i++) {
        PoolBlock* block = (PoolBlock*)((char*)pool->pool + i * pool->block_size);
        block->next = pool->free_list;
        pool->free_list = block;
    }

    return pool;
}

void pool_allocator_destroy(PoolAllocator* pool) {
    if (pool) {
        free(pool->pool);
        free(pool);
    }
}

void* pool_allocator_alloc(PoolAllocator* pool) {
    if (!pool || !pool->free_list) return NULL;

    PoolBlock* block = pool->free_list;
    pool->free_list = block->next;

    return block;
}

void pool_allocator_free(PoolAllocator* pool, void* ptr) {
    if (!pool || !ptr) return;

    PoolBlock* block = (PoolBlock*)ptr;
    block->next = pool->free_list;
    pool->free_list = block;
}

typedef struct ArenaBlock {
    size_t size;
    size_t used;
    struct ArenaBlock* next;
    char data[];
} ArenaBlock;

typedef struct {
    ArenaBlock* current;
    size_t default_block_size;
} ArenaAllocator;

ArenaAllocator* arena_allocator_create(size_t default_block_size) {
    ArenaAllocator* arena = (ArenaAllocator*)malloc(sizeof(ArenaAllocator));
    if (!arena) return NULL;

    arena->default_block_size = default_block_size;
    arena->current = NULL;

    return arena;
}

void arena_allocator_destroy(ArenaAllocator* arena) {
    if (!arena) return;

    ArenaBlock* block = arena->current;
    while (block) {
        ArenaBlock* next = block->next;
        free(block);
        block = next;
    }

    free(arena);
}

void* arena_allocator_alloc(ArenaAllocator* arena, size_t size) {
    if (!arena) return NULL;

    size = align_size(size);

    if (!arena->current || arena->current->used + size > arena->current->size) {
        size_t block_size = size > arena->default_block_size ? size : arena->default_block_size;

        ArenaBlock* new_block = (ArenaBlock*)malloc(sizeof(ArenaBlock) + block_size);
        if (!new_block) return NULL;

        new_block->size = block_size;
        new_block->used = 0;
        new_block->next = arena->current;
        arena->current = new_block;
    }

    void* ptr = arena->current->data + arena->current->used;
    arena->current->used += size;

    return ptr;
}

void arena_allocator_reset(ArenaAllocator* arena) {
    if (!arena) return;

    ArenaBlock* block = arena->current;
    while (block) {
        block->used = 0;
        block = block->next;
    }
}

typedef struct {
    void* stack;
    size_t capacity;
    size_t top;
} StackAllocator;

StackAllocator* stack_allocator_create(size_t capacity) {
    StackAllocator* stack = (StackAllocator*)malloc(sizeof(StackAllocator));
    if (!stack) return NULL;

    stack->stack = malloc(capacity);
    if (!stack->stack) {
        free(stack);
        return NULL;
    }

    stack->capacity = capacity;
    stack->top = 0;

    return stack;
}

void stack_allocator_destroy(StackAllocator* stack) {
    if (stack) {
        free(stack->stack);
        free(stack);
    }
}

void* stack_allocator_alloc(StackAllocator* stack, size_t size) {
    if (!stack) return NULL;

    size = align_size(size);

    if (stack->top + size > stack->capacity) return NULL;

    void* ptr = (char*)stack->stack + stack->top;
    stack->top += size;

    return ptr;
}

void stack_allocator_free_to(StackAllocator* stack, void* marker) {
    if (!stack || !marker) return;

    size_t offset = (char*)marker - (char*)stack->stack;
    if (offset <= stack->capacity) {
        stack->top = offset;
    }
}

void stack_allocator_reset(StackAllocator* stack) {
    if (stack) {
        stack->top = 0;
    }
}

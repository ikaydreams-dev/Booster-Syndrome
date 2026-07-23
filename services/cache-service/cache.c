#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <time.h>

#define MAX_KEY_LENGTH 256
#define MAX_VALUE_LENGTH 4096
#define CACHE_SIZE 10000

typedef struct CacheEntry {
    char key[MAX_KEY_LENGTH];
    char value[MAX_VALUE_LENGTH];
    time_t expiry;
    bool is_valid;
} CacheEntry;

typedef struct Cache {
    CacheEntry entries[CACHE_SIZE];
    int count;
} Cache;

Cache* cache_create() {
    Cache* cache = (Cache*)malloc(sizeof(Cache));
    cache->count = 0;
    for (int i = 0; i < CACHE_SIZE; i++) {
        cache->entries[i].is_valid = false;
    }
    return cache;
}

unsigned int hash(const char* key) {
    unsigned int hash = 5381;
    int c;
    while ((c = *key++)) {
        hash = ((hash << 5) + hash) + c;
    }
    return hash % CACHE_SIZE;
}

bool cache_set(Cache* cache, const char* key, const char* value, int ttl) {
    unsigned int index = hash(key);

    strncpy(cache->entries[index].key, key, MAX_KEY_LENGTH - 1);
    strncpy(cache->entries[index].value, value, MAX_VALUE_LENGTH - 1);
    cache->entries[index].expiry = time(NULL) + ttl;
    cache->entries[index].is_valid = true;

    cache->count++;
    return true;
}

char* cache_get(Cache* cache, const char* key) {
    unsigned int index = hash(key);
    CacheEntry* entry = &cache->entries[index];

    if (!entry->is_valid) {
        return NULL;
    }

    if (strcmp(entry->key, key) != 0) {
        return NULL;
    }

    if (time(NULL) > entry->expiry) {
        entry->is_valid = false;
        return NULL;
    }

    return entry->value;
}

bool cache_delete(Cache* cache, const char* key) {
    unsigned int index = hash(key);
    CacheEntry* entry = &cache->entries[index];

    if (entry->is_valid && strcmp(entry->key, key) == 0) {
        entry->is_valid = false;
        cache->count--;
        return true;
    }

    return false;
}

void cache_clear(Cache* cache) {
    for (int i = 0; i < CACHE_SIZE; i++) {
        cache->entries[i].is_valid = false;
    }
    cache->count = 0;
}

void cache_destroy(Cache* cache) {
    free(cache);
}

int cache_size(Cache* cache) {
    return cache->count;
}

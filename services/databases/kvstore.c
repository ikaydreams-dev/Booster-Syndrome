#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define TABLE_SIZE 1024
#define MAX_KEY_SIZE 256
#define MAX_VALUE_SIZE 1024

typedef struct Entry {
    char key[MAX_KEY_SIZE];
    char value[MAX_VALUE_SIZE];
    struct Entry* next;
} Entry;

typedef struct {
    Entry* buckets[TABLE_SIZE];
    size_t size;
} HashMap;

unsigned int hash(const char* key) {
    unsigned int hash = 5381;
    int c;

    while ((c = *key++)) {
        hash = ((hash << 5) + hash) + c;
    }

    return hash % TABLE_SIZE;
}

HashMap* hashmap_create() {
    HashMap* map = (HashMap*)malloc(sizeof(HashMap));
    map->size = 0;

    for (int i = 0; i < TABLE_SIZE; i++) {
        map->buckets[i] = NULL;
    }

    return map;
}

void hashmap_put(HashMap* map, const char* key, const char* value) {
    unsigned int index = hash(key);
    Entry* entry = map->buckets[index];

    while (entry != NULL) {
        if (strcmp(entry->key, key) == 0) {
            strncpy(entry->value, value, MAX_VALUE_SIZE - 1);
            entry->value[MAX_VALUE_SIZE - 1] = '\0';
            return;
        }
        entry = entry->next;
    }

    Entry* new_entry = (Entry*)malloc(sizeof(Entry));
    strncpy(new_entry->key, key, MAX_KEY_SIZE - 1);
    new_entry->key[MAX_KEY_SIZE - 1] = '\0';
    strncpy(new_entry->value, value, MAX_VALUE_SIZE - 1);
    new_entry->value[MAX_VALUE_SIZE - 1] = '\0';
    new_entry->next = map->buckets[index];
    map->buckets[index] = new_entry;
    map->size++;
}

char* hashmap_get(HashMap* map, const char* key) {
    unsigned int index = hash(key);
    Entry* entry = map->buckets[index];

    while (entry != NULL) {
        if (strcmp(entry->key, key) == 0) {
            return entry->value;
        }
        entry = entry->next;
    }

    return NULL;
}

int hashmap_remove(HashMap* map, const char* key) {
    unsigned int index = hash(key);
    Entry* entry = map->buckets[index];
    Entry* prev = NULL;

    while (entry != NULL) {
        if (strcmp(entry->key, key) == 0) {
            if (prev == NULL) {
                map->buckets[index] = entry->next;
            } else {
                prev->next = entry->next;
            }
            free(entry);
            map->size--;
            return 1;
        }
        prev = entry;
        entry = entry->next;
    }

    return 0;
}

int hashmap_contains(HashMap* map, const char* key) {
    return hashmap_get(map, key) != NULL;
}

size_t hashmap_size(HashMap* map) {
    return map->size;
}

void hashmap_clear(HashMap* map) {
    for (int i = 0; i < TABLE_SIZE; i++) {
        Entry* entry = map->buckets[i];
        while (entry != NULL) {
            Entry* next = entry->next;
            free(entry);
            entry = next;
        }
        map->buckets[i] = NULL;
    }
    map->size = 0;
}

void hashmap_destroy(HashMap* map) {
    hashmap_clear(map);
    free(map);
}

typedef struct {
    char** keys;
    size_t size;
    size_t capacity;
} KeySet;

KeySet* hashmap_keys(HashMap* map) {
    KeySet* keys = (KeySet*)malloc(sizeof(KeySet));
    keys->capacity = map->size;
    keys->size = 0;
    keys->keys = (char**)malloc(keys->capacity * sizeof(char*));

    for (int i = 0; i < TABLE_SIZE; i++) {
        Entry* entry = map->buckets[i];
        while (entry != NULL) {
            keys->keys[keys->size] = (char*)malloc(MAX_KEY_SIZE);
            strcpy(keys->keys[keys->size], entry->key);
            keys->size++;
            entry = entry->next;
        }
    }

    return keys;
}

void keyset_destroy(KeySet* keys) {
    for (size_t i = 0; i < keys->size; i++) {
        free(keys->keys[i]);
    }
    free(keys->keys);
    free(keys);
}

typedef struct LRUNode {
    char key[MAX_KEY_SIZE];
    char value[MAX_VALUE_SIZE];
    struct LRUNode* prev;
    struct LRUNode* next;
} LRUNode;

typedef struct {
    LRUNode* head;
    LRUNode* tail;
    HashMap* map;
    size_t capacity;
    size_t size;
} LRUCache;

LRUCache* lru_create(size_t capacity) {
    LRUCache* cache = (LRUCache*)malloc(sizeof(LRUCache));
    cache->head = NULL;
    cache->tail = NULL;
    cache->map = hashmap_create();
    cache->capacity = capacity;
    cache->size = 0;
    return cache;
}

void lru_move_to_front(LRUCache* cache, LRUNode* node) {
    if (node == cache->head) return;

    if (node->prev) node->prev->next = node->next;
    if (node->next) node->next->prev = node->prev;

    if (node == cache->tail) {
        cache->tail = node->prev;
    }

    node->next = cache->head;
    node->prev = NULL;
    if (cache->head) cache->head->prev = node;
    cache->head = node;

    if (cache->tail == NULL) {
        cache->tail = node;
    }
}

void lru_put(LRUCache* cache, const char* key, const char* value) {
    if (cache->size >= cache->capacity && cache->tail) {
        LRUNode* old = cache->tail;
        cache->tail = old->prev;
        if (cache->tail) {
            cache->tail->next = NULL;
        } else {
            cache->head = NULL;
        }
        hashmap_remove(cache->map, old->key);
        free(old);
        cache->size--;
    }

    LRUNode* node = (LRUNode*)malloc(sizeof(LRUNode));
    strncpy(node->key, key, MAX_KEY_SIZE - 1);
    strncpy(node->value, value, MAX_VALUE_SIZE - 1);
    node->prev = NULL;
    node->next = cache->head;

    if (cache->head) {
        cache->head->prev = node;
    }
    cache->head = node;

    if (cache->tail == NULL) {
        cache->tail = node;
    }

    char addr[32];
    snprintf(addr, sizeof(addr), "%p", (void*)node);
    hashmap_put(cache->map, key, addr);
    cache->size++;
}

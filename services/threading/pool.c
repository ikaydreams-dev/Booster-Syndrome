#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <unistd.h>

#define MAX_THREADS 10
#define QUEUE_SIZE 100

typedef struct {
    void (*function)(void*);
    void* argument;
} task_t;

typedef struct {
    task_t queue[QUEUE_SIZE];
    int head;
    int tail;
    int count;
    pthread_mutex_t lock;
    pthread_cond_t notify;
} task_queue_t;

typedef struct {
    pthread_t threads[MAX_THREADS];
    int thread_count;
    task_queue_t task_queue;
    int shutdown;
} thread_pool_t;

void* worker_thread(void* arg) {
    thread_pool_t* pool = (thread_pool_t*)arg;
    task_t task;

    while (1) {
        pthread_mutex_lock(&pool->task_queue.lock);

        while (pool->task_queue.count == 0 && !pool->shutdown) {
            pthread_cond_wait(&pool->task_queue.notify, &pool->task_queue.lock);
        }

        if (pool->shutdown) {
            pthread_mutex_unlock(&pool->task_queue.lock);
            pthread_exit(NULL);
        }

        task = pool->task_queue.queue[pool->task_queue.head];
        pool->task_queue.head = (pool->task_queue.head + 1) % QUEUE_SIZE;
        pool->task_queue.count--;

        pthread_mutex_unlock(&pool->task_queue.lock);

        (task.function)(task.argument);
    }

    return NULL;
}

thread_pool_t* thread_pool_create(int num_threads) {
    thread_pool_t* pool = malloc(sizeof(thread_pool_t));

    pool->thread_count = num_threads;
    pool->task_queue.head = 0;
    pool->task_queue.tail = 0;
    pool->task_queue.count = 0;
    pool->shutdown = 0;

    pthread_mutex_init(&pool->task_queue.lock, NULL);
    pthread_cond_init(&pool->task_queue.notify, NULL);

    for (int i = 0; i < num_threads; i++) {
        pthread_create(&pool->threads[i], NULL, worker_thread, pool);
    }

    return pool;
}

int thread_pool_add_task(thread_pool_t* pool, void (*function)(void*), void* argument) {
    pthread_mutex_lock(&pool->task_queue.lock);

    if (pool->task_queue.count == QUEUE_SIZE) {
        pthread_mutex_unlock(&pool->task_queue.lock);
        return -1;
    }

    pool->task_queue.queue[pool->task_queue.tail].function = function;
    pool->task_queue.queue[pool->task_queue.tail].argument = argument;
    pool->task_queue.tail = (pool->task_queue.tail + 1) % QUEUE_SIZE;
    pool->task_queue.count++;

    pthread_cond_signal(&pool->task_queue.notify);
    pthread_mutex_unlock(&pool->task_queue.lock);

    return 0;
}

void thread_pool_destroy(thread_pool_t* pool) {
    pthread_mutex_lock(&pool->task_queue.lock);
    pool->shutdown = 1;
    pthread_cond_broadcast(&pool->task_queue.notify);
    pthread_mutex_unlock(&pool->task_queue.lock);

    for (int i = 0; i < pool->thread_count; i++) {
        pthread_join(pool->threads[i], NULL);
    }

    pthread_mutex_destroy(&pool->task_queue.lock);
    pthread_cond_destroy(&pool->task_queue.notify);
    free(pool);
}

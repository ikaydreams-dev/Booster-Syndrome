#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <time.h>
#include <errno.h>

typedef struct {
    pthread_mutex_t mutex;
    pthread_cond_t cond;
    int locked;
} SpinLock;

SpinLock* spinlock_create() {
    SpinLock* lock = (SpinLock*)malloc(sizeof(SpinLock));
    pthread_mutex_init(&lock->mutex, NULL);
    pthread_cond_init(&lock->cond, NULL);
    lock->locked = 0;
    return lock;
}

void spinlock_acquire(SpinLock* lock) {
    pthread_mutex_lock(&lock->mutex);
    while (lock->locked) {
        pthread_cond_wait(&lock->cond, &lock->mutex);
    }
    lock->locked = 1;
    pthread_mutex_unlock(&lock->mutex);
}

int spinlock_try_acquire(SpinLock* lock) {
    pthread_mutex_lock(&lock->mutex);
    int result = 0;
    if (!lock->locked) {
        lock->locked = 1;
        result = 1;
    }
    pthread_mutex_unlock(&lock->mutex);
    return result;
}

void spinlock_release(SpinLock* lock) {
    pthread_mutex_lock(&lock->mutex);
    lock->locked = 0;
    pthread_cond_signal(&lock->cond);
    pthread_mutex_unlock(&lock->mutex);
}

void spinlock_destroy(SpinLock* lock) {
    pthread_mutex_destroy(&lock->mutex);
    pthread_cond_destroy(&lock->cond);
    free(lock);
}

typedef struct {
    pthread_rwlock_t rwlock;
} ReadWriteLock;

ReadWriteLock* rwlock_create() {
    ReadWriteLock* lock = (ReadWriteLock*)malloc(sizeof(ReadWriteLock));
    pthread_rwlock_init(&lock->rwlock, NULL);
    return lock;
}

void rwlock_read_lock(ReadWriteLock* lock) {
    pthread_rwlock_rdlock(&lock->rwlock);
}

void rwlock_write_lock(ReadWriteLock* lock) {
    pthread_rwlock_wrlock(&lock->rwlock);
}

int rwlock_try_read_lock(ReadWriteLock* lock) {
    return pthread_rwlock_tryrdlock(&lock->rwlock) == 0;
}

int rwlock_try_write_lock(ReadWriteLock* lock) {
    return pthread_rwlock_trywrlock(&lock->rwlock) == 0;
}

void rwlock_unlock(ReadWriteLock* lock) {
    pthread_rwlock_unlock(&lock->rwlock);
}

void rwlock_destroy(ReadWriteLock* lock) {
    pthread_rwlock_destroy(&lock->rwlock);
    free(lock);
}

typedef struct {
    pthread_mutex_t mutex;
    int count;
    int max_count;
} Semaphore;

Semaphore* semaphore_create(int initial_count, int max_count) {
    Semaphore* sem = (Semaphore*)malloc(sizeof(Semaphore));
    pthread_mutex_init(&sem->mutex, NULL);
    sem->count = initial_count;
    sem->max_count = max_count;
    return sem;
}

void semaphore_wait(Semaphore* sem) {
    pthread_mutex_lock(&sem->mutex);
    while (sem->count <= 0) {
        pthread_mutex_unlock(&sem->mutex);
        usleep(1000);
        pthread_mutex_lock(&sem->mutex);
    }
    sem->count--;
    pthread_mutex_unlock(&sem->mutex);
}

int semaphore_try_wait(Semaphore* sem) {
    pthread_mutex_lock(&sem->mutex);
    int result = 0;
    if (sem->count > 0) {
        sem->count--;
        result = 1;
    }
    pthread_mutex_unlock(&sem->mutex);
    return result;
}

void semaphore_signal(Semaphore* sem) {
    pthread_mutex_lock(&sem->mutex);
    if (sem->count < sem->max_count) {
        sem->count++;
    }
    pthread_mutex_unlock(&sem->mutex);
}

void semaphore_destroy(Semaphore* sem) {
    pthread_mutex_destroy(&sem->mutex);
    free(sem);
}

typedef struct {
    pthread_mutex_t mutex;
    pthread_cond_t cond;
    int count;
    int threshold;
} Barrier;

Barrier* barrier_create(int threshold) {
    Barrier* barrier = (Barrier*)malloc(sizeof(Barrier));
    pthread_mutex_init(&barrier->mutex, NULL);
    pthread_cond_init(&barrier->cond, NULL);
    barrier->count = 0;
    barrier->threshold = threshold;
    return barrier;
}

void barrier_wait(Barrier* barrier) {
    pthread_mutex_lock(&barrier->mutex);
    barrier->count++;

    if (barrier->count >= barrier->threshold) {
        barrier->count = 0;
        pthread_cond_broadcast(&barrier->cond);
    } else {
        pthread_cond_wait(&barrier->cond, &barrier->mutex);
    }

    pthread_mutex_unlock(&barrier->mutex);
}

void barrier_destroy(Barrier* barrier) {
    pthread_mutex_destroy(&barrier->mutex);
    pthread_cond_destroy(&barrier->cond);
    free(barrier);
}

typedef struct {
    pthread_mutex_t mutex;
    pthread_t owner;
    int count;
} RecursiveMutex;

RecursiveMutex* recursive_mutex_create() {
    RecursiveMutex* rmutex = (RecursiveMutex*)malloc(sizeof(RecursiveMutex));

    pthread_mutexattr_t attr;
    pthread_mutexattr_init(&attr);
    pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE);
    pthread_mutex_init(&rmutex->mutex, &attr);
    pthread_mutexattr_destroy(&attr);

    rmutex->owner = 0;
    rmutex->count = 0;
    return rmutex;
}

void recursive_mutex_lock(RecursiveMutex* rmutex) {
    pthread_mutex_lock(&rmutex->mutex);
    rmutex->owner = pthread_self();
    rmutex->count++;
}

void recursive_mutex_unlock(RecursiveMutex* rmutex) {
    if (pthread_equal(rmutex->owner, pthread_self()) && rmutex->count > 0) {
        rmutex->count--;
        if (rmutex->count == 0) {
            rmutex->owner = 0;
        }
    }
    pthread_mutex_unlock(&rmutex->mutex);
}

void recursive_mutex_destroy(RecursiveMutex* rmutex) {
    pthread_mutex_destroy(&rmutex->mutex);
    free(rmutex);
}

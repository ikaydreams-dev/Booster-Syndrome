import java.util.*;
import java.util.concurrent.*;
import java.util.concurrent.atomic.*;
import java.util.concurrent.locks.*;
import java.util.function.*;

public class Concurrency {

    public static class AsyncTask<T> {
        private CompletableFuture<T> future;

        public AsyncTask(Supplier<T> supplier) {
            this.future = CompletableFuture.supplyAsync(supplier);
        }

        public AsyncTask(Supplier<T> supplier, Executor executor) {
            this.future = CompletableFuture.supplyAsync(supplier, executor);
        }

        public <U> AsyncTask<U> then(Function<T, U> function) {
            CompletableFuture<U> newFuture = future.thenApply(function);
            return new AsyncTask<>(newFuture);
        }

        public <U> AsyncTask<U> thenAsync(Function<T, U> function) {
            CompletableFuture<U> newFuture = future.thenApplyAsync(function);
            return new AsyncTask<>(newFuture);
        }

        public AsyncTask<T> onError(Function<Throwable, T> handler) {
            CompletableFuture<T> newFuture = future.exceptionally(handler);
            return new AsyncTask<>(newFuture);
        }

        public T get() throws InterruptedException, ExecutionException {
            return future.get();
        }

        public T get(long timeout, TimeUnit unit) throws InterruptedException, ExecutionException, TimeoutException {
            return future.get(timeout, unit);
        }

        private AsyncTask(CompletableFuture<T> future) {
            this.future = future;
        }

        public static <T> AsyncTask<List<T>> all(List<AsyncTask<T>> tasks) {
            CompletableFuture<Void> allFutures = CompletableFuture.allOf(
                tasks.stream().map(t -> t.future).toArray(CompletableFuture[]::new)
            );

            return new AsyncTask<>(allFutures.thenApply(v ->
                tasks.stream()
                    .map(t -> t.future.join())
                    .collect(java.util.stream.Collectors.toList())
            ));
        }
    }

    public static class Promise<T> {
        private CompletableFuture<T> future;

        public Promise() {
            this.future = new CompletableFuture<>();
        }

        public void resolve(T value) {
            future.complete(value);
        }

        public void reject(Throwable error) {
            future.completeExceptionally(error);
        }

        public <U> Promise<U> then(Function<T, U> onResolve) {
            Promise<U> newPromise = new Promise<>();

            future.thenApply(value -> {
                try {
                    newPromise.resolve(onResolve.apply(value));
                } catch (Exception e) {
                    newPromise.reject(e);
                }
                return null;
            });

            return newPromise;
        }

        public Promise<T> catchError(Function<Throwable, T> onReject) {
            Promise<T> newPromise = new Promise<>();

            future.whenComplete((value, error) -> {
                if (error != null) {
                    try {
                        newPromise.resolve(onReject.apply(error));
                    } catch (Exception e) {
                        newPromise.reject(e);
                    }
                } else {
                    newPromise.resolve(value);
                }
            });

            return newPromise;
        }

        public T get() throws InterruptedException, ExecutionException {
            return future.get();
        }
    }

    public static class WorkerPool {
        private final ExecutorService executor;
        private final int poolSize;
        private final AtomicInteger activeWorkers;

        public WorkerPool(int poolSize) {
            this.poolSize = poolSize;
            this.executor = Executors.newFixedThreadPool(poolSize);
            this.activeWorkers = new AtomicInteger(0);
        }

        public <T> Future<T> submit(Callable<T> task) {
            activeWorkers.incrementAndGet();

            return executor.submit(() -> {
                try {
                    return task.call();
                } finally {
                    activeWorkers.decrementAndGet();
                }
            });
        }

        public void shutdown() {
            executor.shutdown();
        }

        public void shutdownNow() {
            executor.shutdownNow();
        }

        public int getActiveWorkers() {
            return activeWorkers.get();
        }

        public int getPoolSize() {
            return poolSize;
        }
    }

    public static class BlockingQueue<T> {
        private final Queue<T> queue;
        private final int capacity;
        private final Lock lock;
        private final Condition notFull;
        private final Condition notEmpty;

        public BlockingQueue(int capacity) {
            this.capacity = capacity;
            this.queue = new LinkedList<>();
            this.lock = new ReentrantLock();
            this.notFull = lock.newCondition();
            this.notEmpty = lock.newCondition();
        }

        public void put(T item) throws InterruptedException {
            lock.lock();
            try {
                while (queue.size() >= capacity) {
                    notFull.await();
                }

                queue.offer(item);
                notEmpty.signal();
            } finally {
                lock.unlock();
            }
        }

        public T take() throws InterruptedException {
            lock.lock();
            try {
                while (queue.isEmpty()) {
                    notEmpty.await();
                }

                T item = queue.poll();
                notFull.signal();
                return item;
            } finally {
                lock.unlock();
            }
        }

        public boolean offer(T item, long timeout, TimeUnit unit) throws InterruptedException {
            lock.lock();
            try {
                long nanos = unit.toNanos(timeout);

                while (queue.size() >= capacity) {
                    if (nanos <= 0) {
                        return false;
                    }
                    nanos = notFull.awaitNanos(nanos);
                }

                queue.offer(item);
                notEmpty.signal();
                return true;
            } finally {
                lock.unlock();
            }
        }

        public int size() {
            lock.lock();
            try {
                return queue.size();
            } finally {
                lock.unlock();
            }
        }
    }

    public static class Semaphore {
        private int permits;
        private final Lock lock;
        private final Condition condition;

        public Semaphore(int permits) {
            this.permits = permits;
            this.lock = new ReentrantLock();
            this.condition = lock.newCondition();
        }

        public void acquire() throws InterruptedException {
            lock.lock();
            try {
                while (permits <= 0) {
                    condition.await();
                }
                permits--;
            } finally {
                lock.unlock();
            }
        }

        public void release() {
            lock.lock();
            try {
                permits++;
                condition.signal();
            } finally {
                lock.unlock();
            }
        }

        public boolean tryAcquire() {
            lock.lock();
            try {
                if (permits > 0) {
                    permits--;
                    return true;
                }
                return false;
            } finally {
                lock.unlock();
            }
        }

        public int availablePermits() {
            lock.lock();
            try {
                return permits;
            } finally {
                lock.unlock();
            }
        }
    }

    public static class CountDownLatch {
        private int count;
        private final Lock lock;
        private final Condition condition;

        public CountDownLatch(int count) {
            this.count = count;
            this.lock = new ReentrantLock();
            this.condition = lock.newCondition();
        }

        public void countDown() {
            lock.lock();
            try {
                if (count > 0) {
                    count--;
                    if (count == 0) {
                        condition.signalAll();
                    }
                }
            } finally {
                lock.unlock();
            }
        }

        public void await() throws InterruptedException {
            lock.lock();
            try {
                while (count > 0) {
                    condition.await();
                }
            } finally {
                lock.unlock();
            }
        }

        public boolean await(long timeout, TimeUnit unit) throws InterruptedException {
            lock.lock();
            try {
                long nanos = unit.toNanos(timeout);

                while (count > 0) {
                    if (nanos <= 0) {
                        return false;
                    }
                    nanos = condition.awaitNanos(nanos);
                }
                return true;
            } finally {
                lock.unlock();
            }
        }

        public int getCount() {
            lock.lock();
            try {
                return count;
            } finally {
                lock.unlock();
            }
        }
    }

    public static class CyclicBarrier {
        private final int parties;
        private final Runnable barrierAction;
        private final Lock lock;
        private final Condition condition;
        private int count;
        private int generation;

        public CyclicBarrier(int parties, Runnable barrierAction) {
            this.parties = parties;
            this.barrierAction = barrierAction;
            this.lock = new ReentrantLock();
            this.condition = lock.newCondition();
            this.count = parties;
            this.generation = 0;
        }

        public CyclicBarrier(int parties) {
            this(parties, null);
        }

        public int await() throws InterruptedException {
            lock.lock();
            try {
                int index = --count;
                int gen = generation;

                if (index == 0) {
                    if (barrierAction != null) {
                        barrierAction.run();
                    }

                    generation++;
                    count = parties;
                    condition.signalAll();
                    return 0;
                }

                while (generation == gen) {
                    condition.await();
                }

                return index;
            } finally {
                lock.unlock();
            }
        }

        public void reset() {
            lock.lock();
            try {
                generation++;
                count = parties;
                condition.signalAll();
            } finally {
                lock.unlock();
            }
        }

        public int getParties() {
            return parties;
        }
    }

    public static class ReadWriteLock {
        private int readers = 0;
        private int writers = 0;
        private int writeRequests = 0;
        private final Lock lock = new ReentrantLock();
        private final Condition canRead = lock.newCondition();
        private final Condition canWrite = lock.newCondition();

        public void lockRead() throws InterruptedException {
            lock.lock();
            try {
                while (writers > 0 || writeRequests > 0) {
                    canRead.await();
                }
                readers++;
            } finally {
                lock.unlock();
            }
        }

        public void unlockRead() {
            lock.lock();
            try {
                readers--;
                if (readers == 0) {
                    canWrite.signal();
                }
            } finally {
                lock.unlock();
            }
        }

        public void lockWrite() throws InterruptedException {
            lock.lock();
            try {
                writeRequests++;
                while (readers > 0 || writers > 0) {
                    canWrite.await();
                }
                writeRequests--;
                writers++;
            } finally {
                lock.unlock();
            }
        }

        public void unlockWrite() {
            lock.lock();
            try {
                writers--;
                canWrite.signal();
                canRead.signalAll();
            } finally {
                lock.unlock();
            }
        }
    }

    public static class Atomic<T> {
        private final AtomicReference<T> value;

        public Atomic(T initialValue) {
            this.value = new AtomicReference<>(initialValue);
        }

        public T get() {
            return value.get();
        }

        public void set(T newValue) {
            value.set(newValue);
        }

        public T getAndSet(T newValue) {
            return value.getAndSet(newValue);
        }

        public boolean compareAndSet(T expected, T update) {
            return value.compareAndSet(expected, update);
        }

        public T updateAndGet(UnaryOperator<T> updateFunction) {
            return value.updateAndGet(updateFunction);
        }

        public T getAndUpdate(UnaryOperator<T> updateFunction) {
            return value.getAndUpdate(updateFunction);
        }
    }

    public static class ThreadLocal<T> {
        private final Map<Long, T> values = new ConcurrentHashMap<>();
        private final Supplier<T> initializer;

        public ThreadLocal(Supplier<T> initializer) {
            this.initializer = initializer;
        }

        public T get() {
            long threadId = Thread.currentThread().getId();
            return values.computeIfAbsent(threadId, k -> initializer.get());
        }

        public void set(T value) {
            long threadId = Thread.currentThread().getId();
            values.put(threadId, value);
        }

        public void remove() {
            long threadId = Thread.currentThread().getId();
            values.remove(threadId);
        }
    }
}

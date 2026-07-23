package com.booster.concurrent;

import java.util.concurrent.*;
import java.util.List;
import java.util.ArrayList;
import java.util.stream.Collectors;

public class ParallelProcessor {
    private final ExecutorService executor;
    private final int threadPoolSize;

    public ParallelProcessor(int threadPoolSize) {
        this.threadPoolSize = threadPoolSize;
        this.executor = Executors.newFixedThreadPool(threadPoolSize);
    }

    public <T, R> List<R> processInParallel(List<T> items, Function<T, R> processor) {
        List<Future<R>> futures = new ArrayList<>();

        for (T item : items) {
            Future<R> future = executor.submit(() -> processor.apply(item));
            futures.add(future);
        }

        List<R> results = new ArrayList<>();
        for (Future<R> future : futures) {
            try {
                results.add(future.get());
            } catch (InterruptedException | ExecutionException e) {
                e.printStackTrace();
            }
        }

        return results;
    }

    public <T> void executeBatch(List<Callable<T>> tasks) throws InterruptedException {
        executor.invokeAll(tasks);
    }

    public void shutdown() {
        executor.shutdown();
        try {
            if (!executor.awaitTermination(60, TimeUnit.SECONDS)) {
                executor.shutdownNow();
            }
        } catch (InterruptedException e) {
            executor.shutdownNow();
        }
    }

    @FunctionalInterface
    public interface Function<T, R> {
        R apply(T t);
    }
}

class WorkQueue {
    private final BlockingQueue<Runnable> queue;
    private final List<Thread> workers;
    private volatile boolean running;

    public WorkQueue(int numWorkers) {
        this.queue = new LinkedBlockingQueue<>();
        this.workers = new ArrayList<>();
        this.running = true;

        for (int i = 0; i < numWorkers; i++) {
            Thread worker = new Thread(() -> {
                while (running) {
                    try {
                        Runnable task = queue.take();
                        task.run();
                    } catch (InterruptedException e) {
                        Thread.currentThread().interrupt();
                    }
                }
            });
            worker.start();
            workers.add(worker);
        }
    }

    public void submit(Runnable task) {
        queue.offer(task);
    }

    public void shutdown() throws InterruptedException {
        running = false;
        for (Thread worker : workers) {
            worker.interrupt();
            worker.join();
        }
    }
}

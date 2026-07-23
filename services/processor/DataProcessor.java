package com.booster.processor;

import java.util.*;
import java.util.concurrent.*;
import java.util.stream.*;

public class DataProcessor {
    private final ExecutorService executor;
    private final BlockingQueue<DataItem> queue;
    private final int maxThreads;

    public DataProcessor(int threads) {
        this.maxThreads = threads;
        this.executor = Executors.newFixedThreadPool(threads);
        this.queue = new LinkedBlockingQueue<>(10000);
    }

    public void process(DataItem item) throws InterruptedException {
        queue.put(item);
        executor.submit(() -> processItem(item));
    }

    private void processItem(DataItem item) {
        try {
            item.validate();
            item.transform();
            item.persist();
            System.out.println("Processed: " + item.getId());
        } catch (Exception e) {
            System.err.println("Error processing item: " + e.getMessage());
        }
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

    public int getQueueSize() {
        return queue.size();
    }
}

class DataItem {
    private String id;
    private Map<String, Object> data;
    private long timestamp;

    public DataItem(String id) {
        this.id = id;
        this.data = new HashMap<>();
        this.timestamp = System.currentTimeMillis();
    }

    public String getId() {
        return id;
    }

    public void validate() throws ValidationException {
        if (id == null || id.isEmpty()) {
            throw new ValidationException("ID cannot be empty");
        }
    }

    public void transform() {
        data.put("processed_at", System.currentTimeMillis());
        data.put("status", "transformed");
    }

    public void persist() {
        System.out.println("Persisting data: " + data);
    }
}

class ValidationException extends Exception {
    public ValidationException(String message) {
        super(message);
    }
}

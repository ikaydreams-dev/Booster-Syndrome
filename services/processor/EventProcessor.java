package com.booster.processor;

import java.util.*;
import java.util.concurrent.*;
import java.util.stream.Collectors;
import com.fasterxml.jackson.databind.ObjectMapper;

public class EventProcessor {
    private final BlockingQueue<Event> eventQueue;
    private final ExecutorService executorService;
    private final EventStore eventStore;
    private final MetricsCollector metricsCollector;
    private volatile boolean running;

    public EventProcessor(int threads, int queueSize) {
        this.eventQueue = new LinkedBlockingQueue<>(queueSize);
        this.executorService = Executors.newFixedThreadPool(threads);
        this.eventStore = new EventStore();
        this.metricsCollector = new MetricsCollector();
        this.running = false;
    }

    public void start() {
        running = true;
        for (int i = 0; i < Runtime.getRuntime().availableProcessors(); i++) {
            executorService.submit(this::processEvents);
        }
        System.out.println("Event processor started");
    }

    public void stop() {
        running = false;
        executorService.shutdown();
        try {
            if (!executorService.awaitTermination(60, TimeUnit.SECONDS)) {
                executorService.shutdownNow();
            }
        } catch (InterruptedException e) {
            executorService.shutdownNow();
        }
        System.out.println("Event processor stopped");
    }

    public boolean submitEvent(Event event) {
        try {
            return eventQueue.offer(event, 5, TimeUnit.SECONDS);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            return false;
        }
    }

    private void processEvents() {
        while (running) {
            try {
                Event event = eventQueue.poll(1, TimeUnit.SECONDS);
                if (event != null) {
                    processEvent(event);
                }
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                break;
            }
        }
    }

    private void processEvent(Event event) {
        long startTime = System.currentTimeMillis();

        try {
            // Validate event
            if (!validateEvent(event)) {
                metricsCollector.incrementInvalidEvents();
                return;
            }

            // Enrich event
            enrichEvent(event);

            // Store event
            eventStore.save(event);

            // Update metrics
            metricsCollector.incrementProcessedEvents();
            metricsCollector.recordProcessingTime(System.currentTimeMillis() - startTime);

            // Trigger webhooks
            triggerWebhooks(event);

        } catch (Exception e) {
            metricsCollector.incrementFailedEvents();
            System.err.println("Error processing event: " + e.getMessage());
        }
    }

    private boolean validateEvent(Event event) {
        return event.getId() != null &&
               event.getType() != null &&
               !event.getType().isEmpty();
    }

    private void enrichEvent(Event event) {
        event.setProcessedAt(System.currentTimeMillis());
        event.addProperty("processor_version", "1.0.0");

        if (event.getUserAgent() != null) {
            parseUserAgent(event);
        }

        if (event.getIpAddress() != null) {
            geolocate(event);
        }
    }

    private void parseUserAgent(Event event) {
        String ua = event.getUserAgent().toLowerCase();

        if (ua.contains("mobile")) {
            event.setDeviceType("mobile");
        } else if (ua.contains("tablet")) {
            event.setDeviceType("tablet");
        } else {
            event.setDeviceType("desktop");
        }

        if (ua.contains("chrome")) {
            event.setBrowser("Chrome");
        } else if (ua.contains("firefox")) {
            event.setBrowser("Firefox");
        } else if (ua.contains("safari")) {
            event.setBrowser("Safari");
        }
    }

    private void geolocate(Event event) {
        // GeoIP lookup logic
        event.setCountry("US");
        event.setCity("New York");
    }

    private void triggerWebhooks(Event event) {
        // Webhook triggering logic
    }

    public Map<String, Object> getMetrics() {
        return metricsCollector.getMetrics();
    }
}

class Event {
    private String id;
    private String type;
    private String userId;
    private Long timestamp;
    private Long processedAt;
    private Map<String, Object> properties;
    private String userAgent;
    private String ipAddress;
    private String deviceType;
    private String browser;
    private String country;
    private String city;

    public Event(String id, String type) {
        this.id = id;
        this.type = type;
        this.timestamp = System.currentTimeMillis();
        this.properties = new HashMap<>();
    }

    public String getId() { return id; }
    public String getType() { return type; }
    public String getUserId() { return userId; }
    public Long getTimestamp() { return timestamp; }
    public Long getProcessedAt() { return processedAt; }
    public Map<String, Object> getProperties() { return properties; }
    public String getUserAgent() { return userAgent; }
    public String getIpAddress() { return ipAddress; }
    public String getDeviceType() { return deviceType; }
    public String getBrowser() { return browser; }
    public String getCountry() { return country; }
    public String getCity() { return city; }

    public void setUserId(String userId) { this.userId = userId; }
    public void setProcessedAt(Long processedAt) { this.processedAt = processedAt; }
    public void setUserAgent(String userAgent) { this.userAgent = userAgent; }
    public void setIpAddress(String ipAddress) { this.ipAddress = ipAddress; }
    public void setDeviceType(String deviceType) { this.deviceType = deviceType; }
    public void setBrowser(String browser) { this.browser = browser; }
    public void setCountry(String country) { this.country = country; }
    public void setCity(String city) { this.city = city; }

    public void addProperty(String key, Object value) {
        properties.put(key, value);
    }
}

class EventStore {
    private final Map<String, Event> store = new ConcurrentHashMap<>();

    public void save(Event event) {
        store.put(event.getId(), event);
    }

    public Event get(String id) {
        return store.get(id);
    }
}

class MetricsCollector {
    private final AtomicLong processedEvents = new AtomicLong(0);
    private final AtomicLong invalidEvents = new AtomicLong(0);
    private final AtomicLong failedEvents = new AtomicLong(0);
    private final List<Long> processingTimes = new CopyOnWriteArrayList<>();

    public void incrementProcessedEvents() {
        processedEvents.incrementAndGet();
    }

    public void incrementInvalidEvents() {
        invalidEvents.incrementAndGet();
    }

    public void incrementFailedEvents() {
        failedEvents.incrementAndGet();
    }

    public void recordProcessingTime(long time) {
        processingTimes.add(time);
    }

    public Map<String, Object> getMetrics() {
        Map<String, Object> metrics = new HashMap<>();
        metrics.put("processed", processedEvents.get());
        metrics.put("invalid", invalidEvents.get());
        metrics.put("failed", failedEvents.get());

        if (!processingTimes.isEmpty()) {
            double avg = processingTimes.stream()
                .mapToLong(Long::longValue)
                .average()
                .orElse(0.0);
            metrics.put("avgProcessingTime", avg);
        }

        return metrics;
    }
}

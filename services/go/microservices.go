package main

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"net/http"
	"sync"
	"time"
)

type ServiceRegistry struct {
	services map[string]*ServiceInstance
	mu       sync.RWMutex
}

type ServiceInstance struct {
	ID       string
	Name     string
	Address  string
	Port     int
	Metadata map[string]string
	Health   HealthStatus
}

type HealthStatus string

const (
	Healthy   HealthStatus = "healthy"
	Unhealthy HealthStatus = "unhealthy"
	Unknown   HealthStatus = "unknown"
)

func NewServiceRegistry() *ServiceRegistry {
	return &ServiceRegistry{
		services: make(map[string]*ServiceInstance),
	}
}

func (sr *ServiceRegistry) Register(instance *ServiceInstance) error {
	sr.mu.Lock()
	defer sr.mu.Unlock()

	if instance.ID == "" {
		return errors.New("service ID cannot be empty")
	}

	sr.services[instance.ID] = instance
	return nil
}

func (sr *ServiceRegistry) Deregister(id string) error {
	sr.mu.Lock()
	defer sr.mu.Unlock()

	if _, exists := sr.services[id]; !exists {
		return errors.New("service not found")
	}

	delete(sr.services, id)
	return nil
}

func (sr *ServiceRegistry) Discover(name string) ([]*ServiceInstance, error) {
	sr.mu.RLock()
	defer sr.mu.RUnlock()

	var instances []*ServiceInstance
	for _, instance := range sr.services {
		if instance.Name == name && instance.Health == Healthy {
			instances = append(instances, instance)
		}
	}

	if len(instances) == 0 {
		return nil, errors.New("no healthy instances found")
	}

	return instances, nil
}

func (sr *ServiceRegistry) UpdateHealth(id string, status HealthStatus) error {
	sr.mu.Lock()
	defer sr.mu.Unlock()

	instance, exists := sr.services[id]
	if !exists {
		return errors.New("service not found")
	}

	instance.Health = status
	return nil
}

type APIGateway struct {
	registry *ServiceRegistry
	routes   map[string]RouteConfig
	mu       sync.RWMutex
}

type RouteConfig struct {
	ServiceName string
	Path        string
	Method      string
	Timeout     time.Duration
}

func NewAPIGateway(registry *ServiceRegistry) *APIGateway {
	return &APIGateway{
		registry: registry,
		routes:   make(map[string]RouteConfig),
	}
}

func (gw *APIGateway) AddRoute(path string, config RouteConfig) {
	gw.mu.Lock()
	defer gw.mu.Unlock()
	gw.routes[path] = config
}

func (gw *APIGateway) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	gw.mu.RLock()
	route, exists := gw.routes[r.URL.Path]
	gw.mu.RUnlock()

	if !exists {
		http.Error(w, "Route not found", http.StatusNotFound)
		return
	}

	instances, err := gw.registry.Discover(route.ServiceName)
	if err != nil {
		http.Error(w, "Service unavailable", http.StatusServiceUnavailable)
		return
	}

	instance := instances[0]
	targetURL := fmt.Sprintf("http://%s:%d%s", instance.Address, instance.Port, route.Path)

	ctx, cancel := context.WithTimeout(r.Context(), route.Timeout)
	defer cancel()

	req, err := http.NewRequestWithContext(ctx, r.Method, targetURL, r.Body)
	if err != nil {
		http.Error(w, "Failed to create request", http.StatusInternalServerError)
		return
	}

	for key, values := range r.Header {
		for _, value := range values {
			req.Header.Add(key, value)
		}
	}

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		http.Error(w, "Failed to proxy request", http.StatusBadGateway)
		return
	}
	defer resp.Body.Close()

	for key, values := range resp.Header {
		for _, value := range values {
			w.Header().Add(key, value)
		}
	}

	w.WriteHeader(resp.StatusCode)
	buf := make([]byte, 32*1024)
	for {
		n, err := resp.Body.Read(buf)
		if n > 0 {
			w.Write(buf[:n])
		}
		if err != nil {
			break
		}
	}
}

type EventBus struct {
	subscribers map[string][]chan Event
	mu          sync.RWMutex
}

type Event struct {
	Type      string
	Payload   interface{}
	Timestamp time.Time
}

func NewEventBus() *EventBus {
	return &EventBus{
		subscribers: make(map[string][]chan Event),
	}
}

func (eb *EventBus) Subscribe(eventType string) <-chan Event {
	eb.mu.Lock()
	defer eb.mu.Unlock()

	ch := make(chan Event, 100)
	eb.subscribers[eventType] = append(eb.subscribers[eventType], ch)
	return ch
}

func (eb *EventBus) Publish(event Event) {
	eb.mu.RLock()
	defer eb.mu.RUnlock()

	event.Timestamp = time.Now()

	if subscribers, exists := eb.subscribers[event.Type]; exists {
		for _, ch := range subscribers {
			select {
			case ch <- event:
			default:
				log.Printf("Subscriber channel full for event type: %s", event.Type)
			}
		}
	}
}

type MessageQueue struct {
	queues map[string]chan Message
	mu     sync.RWMutex
}

type Message struct {
	ID      string
	Topic   string
	Payload []byte
	Headers map[string]string
}

func NewMessageQueue() *MessageQueue {
	return &MessageQueue{
		queues: make(map[string]chan Message),
	}
}

func (mq *MessageQueue) CreateQueue(name string, size int) {
	mq.mu.Lock()
	defer mq.mu.Unlock()

	mq.queues[name] = make(chan Message, size)
}

func (mq *MessageQueue) Enqueue(queueName string, msg Message) error {
	mq.mu.RLock()
	queue, exists := mq.queues[queueName]
	mq.mu.RUnlock()

	if !exists {
		return errors.New("queue not found")
	}

	select {
	case queue <- msg:
		return nil
	default:
		return errors.New("queue is full")
	}
}

func (mq *MessageQueue) Dequeue(queueName string) (Message, error) {
	mq.mu.RLock()
	queue, exists := mq.queues[queueName]
	mq.mu.RUnlock()

	if !exists {
		return Message{}, errors.New("queue not found")
	}

	select {
	case msg := <-queue:
		return msg, nil
	case <-time.After(1 * time.Second):
		return Message{}, errors.New("queue is empty")
	}
}

type HealthChecker struct {
	checks map[string]HealthCheck
	mu     sync.RWMutex
}

type HealthCheck func() error

func NewHealthChecker() *HealthChecker {
	return &HealthChecker{
		checks: make(map[string]HealthCheck),
	}
}

func (hc *HealthChecker) Register(name string, check HealthCheck) {
	hc.mu.Lock()
	defer hc.mu.Unlock()
	hc.checks[name] = check
}

func (hc *HealthChecker) Check() map[string]string {
	hc.mu.RLock()
	defer hc.mu.RUnlock()

	results := make(map[string]string)
	for name, check := range hc.checks {
		if err := check(); err != nil {
			results[name] = fmt.Sprintf("unhealthy: %v", err)
		} else {
			results[name] = "healthy"
		}
	}

	return results
}

type ConfigManager struct {
	config map[string]interface{}
	mu     sync.RWMutex
}

func NewConfigManager() *ConfigManager {
	return &ConfigManager{
		config: make(map[string]interface{}),
	}
}

func (cm *ConfigManager) Set(key string, value interface{}) {
	cm.mu.Lock()
	defer cm.mu.Unlock()
	cm.config[key] = value
}

func (cm *ConfigManager) Get(key string) (interface{}, bool) {
	cm.mu.RLock()
	defer cm.mu.RUnlock()
	value, exists := cm.config[key]
	return value, exists
}

func (cm *ConfigManager) GetString(key string) string {
	if value, exists := cm.Get(key); exists {
		if str, ok := value.(string); ok {
			return str
		}
	}
	return ""
}

func (cm *ConfigManager) GetInt(key string) int {
	if value, exists := cm.Get(key); exists {
		if num, ok := value.(int); ok {
			return num
		}
	}
	return 0
}

type Metrics struct {
	counters   map[string]int64
	gauges     map[string]float64
	histograms map[string][]float64
	mu         sync.RWMutex
}

func NewMetrics() *Metrics {
	return &Metrics{
		counters:   make(map[string]int64),
		gauges:     make(map[string]float64),
		histograms: make(map[string][]float64),
	}
}

func (m *Metrics) IncrementCounter(name string) {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.counters[name]++
}

func (m *Metrics) SetGauge(name string, value float64) {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.gauges[name] = value
}

func (m *Metrics) RecordHistogram(name string, value float64) {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.histograms[name] = append(m.histograms[name], value)
}

func (m *Metrics) GetCounter(name string) int64 {
	m.mu.RLock()
	defer m.mu.RUnlock()
	return m.counters[name]
}

func (m *Metrics) GetGauge(name string) float64 {
	m.mu.RLock()
	defer m.mu.RUnlock()
	return m.gauges[name]
}

func (m *Metrics) Export() map[string]interface{} {
	m.mu.RLock()
	defer m.mu.RUnlock()

	return map[string]interface{}{
		"counters":   m.counters,
		"gauges":     m.gauges,
		"histograms": m.histograms,
	}
}

type Tracer struct {
	spans []Span
	mu    sync.Mutex
}

type Span struct {
	TraceID   string
	SpanID    string
	Operation string
	StartTime time.Time
	EndTime   time.Time
	Tags      map[string]string
}

func NewTracer() *Tracer {
	return &Tracer{
		spans: make([]Span, 0),
	}
}

func (t *Tracer) StartSpan(operation string) *Span {
	span := &Span{
		TraceID:   generateID(),
		SpanID:    generateID(),
		Operation: operation,
		StartTime: time.Now(),
		Tags:      make(map[string]string),
	}

	return span
}

func (t *Tracer) FinishSpan(span *Span) {
	span.EndTime = time.Now()

	t.mu.Lock()
	defer t.mu.Unlock()
	t.spans = append(t.spans, *span)
}

func (t *Tracer) GetSpans() []Span {
	t.mu.Lock()
	defer t.mu.Unlock()
	return append([]Span{}, t.spans...)
}

func generateID() string {
	return fmt.Sprintf("%d", time.Now().UnixNano())
}

type RateLimitMiddleware struct {
	limiter map[string]*TokenBucket
	mu      sync.RWMutex
}

type TokenBucket struct {
	tokens    float64
	capacity  float64
	rate      float64
	lastCheck time.Time
	mu        sync.Mutex
}

func NewRateLimitMiddleware(capacity, rate float64) *RateLimitMiddleware {
	return &RateLimitMiddleware{
		limiter: make(map[string]*TokenBucket),
	}
}

func (rl *RateLimitMiddleware) Allow(clientID string) bool {
	rl.mu.RLock()
	bucket, exists := rl.limiter[clientID]
	rl.mu.RUnlock()

	if !exists {
		rl.mu.Lock()
		bucket = &TokenBucket{
			tokens:    100,
			capacity:  100,
			rate:      10,
			lastCheck: time.Now(),
		}
		rl.limiter[clientID] = bucket
		rl.mu.Unlock()
	}

	return bucket.Take()
}

func (tb *TokenBucket) Take() bool {
	tb.mu.Lock()
	defer tb.mu.Unlock()

	now := time.Now()
	elapsed := now.Sub(tb.lastCheck).Seconds()

	tb.tokens += elapsed * tb.rate
	if tb.tokens > tb.capacity {
		tb.tokens = tb.capacity
	}

	tb.lastCheck = now

	if tb.tokens >= 1 {
		tb.tokens--
		return true
	}

	return false
}

type JSONResponse struct {
	Success bool        `json:"success"`
	Data    interface{} `json:"data,omitempty"`
	Error   string      `json:"error,omitempty"`
}

func WriteJSON(w http.ResponseWriter, status int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(data)
}

package metrics

import (
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
)

var (
	RequestsTotal = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "http_requests_total",
			Help: "Total number of HTTP requests",
		},
		[]string{"method", "endpoint", "status"},
	)

	RequestDuration = promauto.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:    "http_request_duration_seconds",
			Help:    "HTTP request latencies in seconds",
			Buckets: prometheus.DefBuckets,
		},
		[]string{"method", "endpoint"},
	)

	ActiveConnections = promauto.NewGauge(
		prometheus.GaugeOpts{
			Name: "active_connections",
			Help: "Number of active connections",
		},
	)

	DatabaseQueriesTotal = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "database_queries_total",
			Help: "Total number of database queries",
		},
		[]string{"operation", "table"},
	)

	DatabaseQueryDuration = promauto.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:    "database_query_duration_seconds",
			Help:    "Database query duration in seconds",
			Buckets: prometheus.DefBuckets,
		},
		[]string{"operation", "table"},
	)

	CacheHitsTotal = promauto.NewCounter(
		prometheus.CounterOpts{
			Name: "cache_hits_total",
			Help: "Total number of cache hits",
		},
	)

	CacheMissesTotal = promauto.NewCounter(
		prometheus.CounterOpts{
			Name: "cache_misses_total",
			Help: "Total number of cache misses",
		},
	)

	QueueSize = promauto.NewGaugeVec(
		prometheus.GaugeOpts{
			Name: "queue_size",
			Help: "Current size of message queues",
		},
		[]string{"queue_name"},
	)

	EventsProcessedTotal = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "events_processed_total",
			Help: "Total number of events processed",
		},
		[]string{"event_type"},
	)

	EventProcessingErrors = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "event_processing_errors_total",
			Help: "Total number of event processing errors",
		},
		[]string{"event_type", "error_type"},
	)

	WebSocketConnections = promauto.NewGauge(
		prometheus.GaugeOpts{
			Name: "websocket_connections",
			Help: "Current number of WebSocket connections",
		},
	)
)

func RecordRequest(method, endpoint, status string, duration float64) {
	RequestsTotal.WithLabelValues(method, endpoint, status).Inc()
	RequestDuration.WithLabelValues(method, endpoint).Observe(duration)
}

func RecordDatabaseQuery(operation, table string, duration float64) {
	DatabaseQueriesTotal.WithLabelValues(operation, table).Inc()
	DatabaseQueryDuration.WithLabelValues(operation, table).Observe(duration)
}

func RecordCacheHit() {
	CacheHitsTotal.Inc()
}

func RecordCacheMiss() {
	CacheMissesTotal.Inc()
}

func SetQueueSize(queueName string, size int) {
	QueueSize.WithLabelValues(queueName).Set(float64(size))
}

func RecordEventProcessed(eventType string) {
	EventsProcessedTotal.WithLabelValues(eventType).Inc()
}

func RecordEventError(eventType, errorType string) {
	EventProcessingErrors.WithLabelValues(eventType, errorType).Inc()
}

func IncrementActiveConnections() {
	ActiveConnections.Inc()
}

func DecrementActiveConnections() {
	ActiveConnections.Dec()
}

func IncrementWebSocketConnections() {
	WebSocketConnections.Inc()
}

func DecrementWebSocketConnections() {
	WebSocketConnections.Dec()
}

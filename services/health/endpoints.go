package health

import (
	"context"
	"database/sql"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/go-redis/redis/v8"
)

type HealthCheck struct {
	db    *sql.DB
	redis *redis.Client
}

type HealthStatus struct {
	Status    string            `json:"status"`
	Timestamp string            `json:"timestamp"`
	Checks    map[string]string `json:"checks"`
}

func NewHealthCheck(db *sql.DB, redis *redis.Client) *HealthCheck {
	return &HealthCheck{
		db:    db,
		redis: redis,
	}
}

func (h *HealthCheck) LivenessHandler(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"status": "alive",
	})
}

func (h *HealthCheck) ReadinessHandler(c *gin.Context) {
	checks := make(map[string]string)
	allHealthy := true

	if err := h.checkDatabase(); err != nil {
		checks["database"] = "unhealthy: " + err.Error()
		allHealthy = false
	} else {
		checks["database"] = "healthy"
	}

	if err := h.checkRedis(); err != nil {
		checks["redis"] = "unhealthy: " + err.Error()
		allHealthy = false
	} else {
		checks["redis"] = "healthy"
	}

	status := "ready"
	statusCode := http.StatusOK

	if !allHealthy {
		status = "not_ready"
		statusCode = http.StatusServiceUnavailable
	}

	c.JSON(statusCode, HealthStatus{
		Status:    status,
		Timestamp: time.Now().UTC().Format(time.RFC3339),
		Checks:    checks,
	})
}

func (h *HealthCheck) HealthHandler(c *gin.Context) {
	checks := make(map[string]string)
	allHealthy := true

	if err := h.checkDatabase(); err != nil {
		checks["database"] = "unhealthy: " + err.Error()
		allHealthy = false
	} else {
		checks["database"] = "healthy"
	}

	if err := h.checkRedis(); err != nil {
		checks["redis"] = "unhealthy: " + err.Error()
		allHealthy = false
	} else {
		checks["redis"] = "healthy"
	}

	status := "healthy"
	statusCode := http.StatusOK

	if !allHealthy {
		status = "unhealthy"
		statusCode = http.StatusServiceUnavailable
	}

	c.JSON(statusCode, HealthStatus{
		Status:    status,
		Timestamp: time.Now().UTC().Format(time.RFC3339),
		Checks:    checks,
	})
}

func (h *HealthCheck) checkDatabase() error {
	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()

	return h.db.PingContext(ctx)
}

func (h *HealthCheck) checkRedis() error {
	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()

	return h.redis.Ping(ctx).Err()
}

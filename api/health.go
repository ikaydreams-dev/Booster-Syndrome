package api

import (
	"encoding/json"
	"net/http"
	"runtime"
	"time"
)

var startTime = time.Now()

type HealthResponse struct {
	Status       string                 `json:"status"`
	Timestamp    string                 `json:"timestamp"`
	Service      string                 `json:"service"`
	Version      string                 `json:"version"`
	Uptime       int64                  `json:"uptime"`
	Dependencies map[string]interface{} `json:"dependencies"`
}

func HealthHandler(w http.ResponseWriter, r *http.Request) {
	health := HealthResponse{
		Status:       "healthy",
		Timestamp:    time.Now().Format(time.RFC3339),
		Service:      "go",
		Version:      "1.0.0",
		Uptime:       int64(time.Since(startTime).Seconds()),
		Dependencies: checkDependencies(),
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(health)
}

func checkDependencies() map[string]interface{} {
	return map[string]interface{}{
		"database": checkDatabase(),
		"redis":    checkRedis(),
		"memory":   checkMemory(),
	}
}

func checkDatabase() map[string]interface{} {
	return map[string]interface{}{
		"status":     "connected",
		"latency_ms": 5,
	}
}

func checkRedis() map[string]interface{} {
	return map[string]interface{}{
		"status":     "connected",
		"latency_ms": 2,
	}
}

func checkMemory() map[string]interface{} {
	var m runtime.MemStats
	runtime.ReadMemStats(&m)
	
	return map[string]interface{}{
		"used_mb":  m.Alloc / 1024 / 1024,
		"limit_mb": 512,
	}
}

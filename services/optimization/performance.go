package optimization

import (
	"runtime"
	"sync"
	"time"
)

type PerformanceMonitor struct {
	mu             sync.RWMutex
	startTime      time.Time
	requestCount   uint64
	errorCount     uint64
	totalDuration  time.Duration
}

func NewPerformanceMonitor() *PerformanceMonitor {
	return &PerformanceMonitor{
		startTime: time.Now(),
	}
}

func (pm *PerformanceMonitor) RecordRequest(duration time.Duration, isError bool) {
	pm.mu.Lock()
	defer pm.mu.Unlock()

	pm.requestCount++
	pm.totalDuration += duration

	if isError {
		pm.errorCount++
	}
}

func (pm *PerformanceMonitor) GetStats() map[string]interface{} {
	pm.mu.RLock()
	defer pm.mu.RUnlock()

	uptime := time.Since(pm.startTime)
	avgDuration := time.Duration(0)
	if pm.requestCount > 0 {
		avgDuration = pm.totalDuration / time.Duration(pm.requestCount)
	}

	var m runtime.MemStats
	runtime.ReadMemStats(&m)

	return map[string]interface{}{
		"uptime_seconds":    uptime.Seconds(),
		"total_requests":    pm.requestCount,
		"error_count":       pm.errorCount,
		"error_rate":        float64(pm.errorCount) / float64(pm.requestCount),
		"avg_duration_ms":   avgDuration.Milliseconds(),
		"memory_alloc_mb":   float64(m.Alloc) / 1024 / 1024,
		"memory_sys_mb":     float64(m.Sys) / 1024 / 1024,
		"num_goroutines":    runtime.NumGoroutine(),
		"num_cpu":           runtime.NumCPU(),
	}
}

type ObjectPool struct {
	pool *sync.Pool
}

func NewObjectPool(factory func() interface{}) *ObjectPool {
	return &ObjectPool{
		pool: &sync.Pool{
			New: factory,
		},
	}
}

func (op *ObjectPool) Get() interface{} {
	return op.pool.Get()
}

func (op *ObjectPool) Put(obj interface{}) {
	op.pool.Put(obj)
}

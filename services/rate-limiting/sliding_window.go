package ratelimiting

import (
	"sync"
	"time"
)

type Request struct {
	Timestamp time.Time
}

type SlidingWindowRateLimiter struct {
	mu       sync.RWMutex
	requests map[string][]Request
	limit    int
	window   time.Duration
}

func NewSlidingWindowRateLimiter(limit int, window time.Duration) *SlidingWindowRateLimiter {
	limiter := &SlidingWindowRateLimiter{
		requests: make(map[string][]Request),
		limit:    limit,
		window:   window,
	}

	go limiter.cleanup()

	return limiter
}

func (rl *SlidingWindowRateLimiter) Allow(key string) bool {
	rl.mu.Lock()
	defer rl.mu.Unlock()

	now := time.Now()
	windowStart := now.Add(-rl.window)

	if _, exists := rl.requests[key]; !exists {
		rl.requests[key] = []Request{}
	}

	validRequests := []Request{}
	for _, req := range rl.requests[key] {
		if req.Timestamp.After(windowStart) {
			validRequests = append(validRequests, req)
		}
	}

	rl.requests[key] = validRequests

	if len(validRequests) >= rl.limit {
		return false
	}

	rl.requests[key] = append(rl.requests[key], Request{Timestamp: now})

	return true
}

func (rl *SlidingWindowRateLimiter) Remaining(key string) int {
	rl.mu.RLock()
	defer rl.mu.RUnlock()

	now := time.Now()
	windowStart := now.Add(-rl.window)

	validCount := 0
	if requests, exists := rl.requests[key]; exists {
		for _, req := range requests {
			if req.Timestamp.After(windowStart) {
				validCount++
			}
		}
	}

	remaining := rl.limit - validCount
	if remaining < 0 {
		remaining = 0
	}

	return remaining
}

func (rl *SlidingWindowRateLimiter) Reset(key string) {
	rl.mu.Lock()
	defer rl.mu.Unlock()

	delete(rl.requests, key)
}

func (rl *SlidingWindowRateLimiter) cleanup() {
	ticker := time.NewTicker(time.Minute)
	defer ticker.Stop()

	for range ticker.C {
		rl.mu.Lock()

		now := time.Now()
		windowStart := now.Add(-rl.window)

		for key, requests := range rl.requests {
			validRequests := []Request{}
			for _, req := range requests {
				if req.Timestamp.After(windowStart) {
					validRequests = append(validRequests, req)
				}
			}

			if len(validRequests) == 0 {
				delete(rl.requests, key)
			} else {
				rl.requests[key] = validRequests
			}
		}

		rl.mu.Unlock()
	}
}

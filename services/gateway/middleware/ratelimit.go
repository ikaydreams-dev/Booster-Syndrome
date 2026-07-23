package middleware

import (
	"net/http"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
)

type visitor struct {
	lastSeen time.Time
	count    int
}

type RateLimiter struct {
	visitors map[string]*visitor
	mu       sync.RWMutex
	limit    int
	window   time.Duration
}

// NewRateLimiter creates a new rate limiter
func NewRateLimiter(limit int, window time.Duration) *RateLimiter {
	rl := &RateLimiter{
		visitors: make(map[string]*visitor),
		limit:    limit,
		window:   window,
	}

	// Cleanup expired visitors every minute
	go rl.cleanupVisitors()

	return rl
}

// RateLimit middleware
func (rl *RateLimiter) RateLimit() gin.HandlerFunc {
	return func(c *gin.Context) {
		ip := c.ClientIP()

		rl.mu.Lock()
		v, exists := rl.visitors[ip]

		if !exists {
			rl.visitors[ip] = &visitor{
				lastSeen: time.Now(),
				count:    1,
			}
			rl.mu.Unlock()
			c.Next()
			return
		}

		// Reset counter if window has passed
		if time.Since(v.lastSeen) > rl.window {
			v.count = 1
			v.lastSeen = time.Now()
			rl.mu.Unlock()
			c.Next()
			return
		}

		// Check if limit exceeded
		if v.count >= rl.limit {
			rl.mu.Unlock()
			c.JSON(http.StatusTooManyRequests, gin.H{
				"error":      "Rate limit exceeded",
				"retry_after": int(rl.window.Seconds()),
			})
			c.Abort()
			return
		}

		v.count++
		v.lastSeen = time.Now()
		rl.mu.Unlock()

		c.Next()
	}
}

// cleanupVisitors removes expired visitor records
func (rl *RateLimiter) cleanupVisitors() {
	ticker := time.NewTicker(1 * time.Minute)
	defer ticker.Stop()

	for range ticker.C {
		rl.mu.Lock()
		for ip, v := range rl.visitors {
			if time.Since(v.lastSeen) > rl.window*2 {
				delete(rl.visitors, ip)
			}
		}
		rl.mu.Unlock()
	}
}

// PerUserRateLimit limits requests per authenticated user
func PerUserRateLimit(limit int, window time.Duration) gin.HandlerFunc {
	limiter := NewRateLimiter(limit, window)

	return func(c *gin.Context) {
		userID := GetUserID(c)
		if userID == "" {
			// Fall back to IP-based limiting for unauthenticated users
			limiter.RateLimit()(c)
			return
		}

		limiter.mu.Lock()
		v, exists := limiter.visitors[userID]

		if !exists {
			limiter.visitors[userID] = &visitor{
				lastSeen: time.Now(),
				count:    1,
			}
			limiter.mu.Unlock()
			c.Next()
			return
		}

		if time.Since(v.lastSeen) > window {
			v.count = 1
			v.lastSeen = time.Now()
			limiter.mu.Unlock()
			c.Next()
			return
		}

		if v.count >= limit {
			limiter.mu.Unlock()
			c.JSON(http.StatusTooManyRequests, gin.H{
				"error":      "Rate limit exceeded",
				"retry_after": int(window.Seconds()),
			})
			c.Abort()
			return
		}

		v.count++
		v.lastSeen = time.Now()
		limiter.mu.Unlock()

		c.Next()
	}
}

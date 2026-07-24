package main

import (
	"testing"
	"time"
)

func TestRateLimiter(t *testing.T) {
	limiter := NewRateLimiter(10, time.Second)
	
	if !limiter.Allow() {
		t.Error("First request should be allowed")
	}
}

func TestLoadBalancer(t *testing.T) {
	backends := []string{"server1", "server2", "server3"}
	lb := NewLoadBalancer(backends)
	
	backend := lb.NextBackend()
	if backend == "" {
		t.Error("Should return a backend")
	}
}

func TestConnectionPool(t *testing.T) {
	pool := NewConnectionPool(5, func() (interface{}, error) {
		return "connection", nil
	})
	
	if pool == nil {
		t.Error("Pool should not be nil")
	}
}

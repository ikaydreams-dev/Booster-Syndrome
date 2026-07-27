package patterns

import (
	"context"
	"fmt"
	"math"
	"time"
)

type RetryPolicy struct {
	MaxAttempts     int
	InitialDelay    time.Duration
	MaxDelay        time.Duration
	Multiplier      float64
	RandomizeFactor float64
}

func NewRetryPolicy() *RetryPolicy {
	return &RetryPolicy{
		MaxAttempts:     3,
		InitialDelay:    time.Second,
		MaxDelay:        30 * time.Second,
		Multiplier:      2.0,
		RandomizeFactor: 0.1,
	}
}

func (p *RetryPolicy) Execute(ctx context.Context, fn func() error) error {
	var err error
	
	for attempt := 0; attempt < p.MaxAttempts; attempt++ {
		err = fn()
		
		if err == nil {
			return nil
		}

		if attempt < p.MaxAttempts-1 {
			delay := p.calculateDelay(attempt)
			
			select {
			case <-time.After(delay):
				// Continue to next attempt
			case <-ctx.Done():
				return fmt.Errorf("retry cancelled: %w", ctx.Err())
			}
		}
	}

	return fmt.Errorf("max retry attempts exceeded: %w", err)
}

func (p *RetryPolicy) calculateDelay(attempt int) time.Duration {
	// Exponential backoff
	delay := float64(p.InitialDelay) * math.Pow(p.Multiplier, float64(attempt))
	
	// Apply max delay
	if delay > float64(p.MaxDelay) {
		delay = float64(p.MaxDelay)
	}

	// Add jitter
	if p.RandomizeFactor > 0 {
		jitter := delay * p.RandomizeFactor
		delay = delay - jitter + (jitter * 2 * float64(time.Now().UnixNano()%100) / 100)
	}

	return time.Duration(delay)
}

type RetryableFunc func() error

func WithRetry(maxAttempts int, fn RetryableFunc) error {
	policy := &RetryPolicy{
		MaxAttempts:  maxAttempts,
		InitialDelay: time.Second,
		MaxDelay:     30 * time.Second,
		Multiplier:   2.0,
	}
	
	return policy.Execute(context.Background(), fn)
}

func WithRetryAndBackoff(maxAttempts int, initialDelay time.Duration, fn RetryableFunc) error {
	policy := &RetryPolicy{
		MaxAttempts:  maxAttempts,
		InitialDelay: initialDelay,
		MaxDelay:     30 * time.Second,
		Multiplier:   2.0,
	}
	
	return policy.Execute(context.Background(), fn)
}

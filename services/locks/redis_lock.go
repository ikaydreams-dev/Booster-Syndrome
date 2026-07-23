package locks

import (
	"context"
	"errors"
	"time"

	"github.com/go-redis/redis/v8"
	"github.com/google/uuid"
)

var (
	ErrLockNotAcquired = errors.New("lock not acquired")
	ErrLockNotHeld     = errors.New("lock not held")
)

type RedisLock struct {
	client *redis.Client
	key    string
	value  string
	ttl    time.Duration
}

func NewRedisLock(client *redis.Client, key string, ttl time.Duration) *RedisLock {
	return &RedisLock{
		client: client,
		key:    key,
		value:  uuid.New().String(),
		ttl:    ttl,
	}
}

func (l *RedisLock) Acquire(ctx context.Context) error {
	success, err := l.client.SetNX(ctx, l.key, l.value, l.ttl).Result()
	if err != nil {
		return err
	}

	if !success {
		return ErrLockNotAcquired
	}

	return nil
}

func (l *RedisLock) Release(ctx context.Context) error {
	script := `
		if redis.call("get", KEYS[1]) == ARGV[1] then
			return redis.call("del", KEYS[1])
		else
			return 0
		end
	`

	result, err := l.client.Eval(ctx, script, []string{l.key}, l.value).Result()
	if err != nil {
		return err
	}

	if result.(int64) == 0 {
		return ErrLockNotHeld
	}

	return nil
}

func (l *RedisLock) Extend(ctx context.Context) error {
	script := `
		if redis.call("get", KEYS[1]) == ARGV[1] then
			return redis.call("pexpire", KEYS[1], ARGV[2])
		else
			return 0
		end
	`

	result, err := l.client.Eval(ctx, script, []string{l.key}, l.value, l.ttl.Milliseconds()).Result()
	if err != nil {
		return err
	}

	if result.(int64) == 0 {
		return ErrLockNotHeld
	}

	return nil
}

func (l *RedisLock) TryAcquire(ctx context.Context, retries int, retryDelay time.Duration) error {
	for i := 0; i < retries; i++ {
		err := l.Acquire(ctx)
		if err == nil {
			return nil
		}

		if err != ErrLockNotAcquired {
			return err
		}

		if i < retries-1 {
			time.Sleep(retryDelay)
		}
	}

	return ErrLockNotAcquired
}

type DistributedLockManager struct {
	client *redis.Client
}

func NewDistributedLockManager(client *redis.Client) *DistributedLockManager {
	return &DistributedLockManager{client: client}
}

func (m *DistributedLockManager) Lock(key string, ttl time.Duration) *RedisLock {
	return NewRedisLock(m.client, key, ttl)
}

func (m *DistributedLockManager) WithLock(ctx context.Context, key string, ttl time.Duration, fn func() error) error {
	lock := NewRedisLock(m.client, key, ttl)

	if err := lock.Acquire(ctx); err != nil {
		return err
	}

	defer lock.Release(ctx)

	return fn()
}

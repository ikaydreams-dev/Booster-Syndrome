package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"time"

	"github.com/go-redis/redis/v8"
)

type CacheProxy struct {
	client *redis.Client
	ctx    context.Context
}

func NewCacheProxy(addr string) *CacheProxy {
	client := redis.NewClient(&redis.Options{
		Addr:         addr,
		Password:     "",
		DB:           0,
		DialTimeout:  5 * time.Second,
		ReadTimeout:  3 * time.Second,
		WriteTimeout: 3 * time.Second,
		PoolSize:     10,
	})

	ctx := context.Background()

	if _, err := client.Ping(ctx).Result(); err != nil {
		log.Fatalf("Failed to connect to Redis: %v", err)
	}

	return &CacheProxy{
		client: client,
		ctx:    ctx,
	}
}

func (cp *CacheProxy) Get(key string) (string, error) {
	val, err := cp.client.Get(cp.ctx, key).Result()
	if err == redis.Nil {
		return "", fmt.Errorf("key not found")
	}
	return val, err
}

func (cp *CacheProxy) Set(key string, value interface{}, ttl time.Duration) error {
	var data string

	switch v := value.(type) {
	case string:
		data = v
	default:
		bytes, err := json.Marshal(v)
		if err != nil {
			return err
		}
		data = string(bytes)
	}

	return cp.client.Set(cp.ctx, key, data, ttl).Err()
}

func (cp *CacheProxy) Delete(key string) error {
	return cp.client.Del(cp.ctx, key).Err()
}

func (cp *CacheProxy) Exists(key string) (bool, error) {
	count, err := cp.client.Exists(cp.ctx, key).Result()
	return count > 0, err
}

func (cp *CacheProxy) Increment(key string) (int64, error) {
	return cp.client.Incr(cp.ctx, key).Result()
}

func (cp *CacheProxy) Decrement(key string) (int64, error) {
	return cp.client.Decr(cp.ctx, key).Result()
}

func (cp *CacheProxy) HSet(key, field string, value interface{}) error {
	return cp.client.HSet(cp.ctx, key, field, value).Err()
}

func (cp *CacheProxy) HGet(key, field string) (string, error) {
	return cp.client.HGet(cp.ctx, key, field).Result()
}

func (cp *CacheProxy) HGetAll(key string) (map[string]string, error) {
	return cp.client.HGetAll(cp.ctx, key).Result()
}

func (cp *CacheProxy) SAdd(key string, members ...interface{}) error {
	return cp.client.SAdd(cp.ctx, key, members...).Err()
}

func (cp *CacheProxy) SMembers(key string) ([]string, error) {
	return cp.client.SMembers(cp.ctx, key).Result()
}

func (cp *CacheProxy) ZAdd(key string, members ...*redis.Z) error {
	return cp.client.ZAdd(cp.ctx, key, members...).Err()
}

func (cp *CacheProxy) ZRange(key string, start, stop int64) ([]string, error) {
	return cp.client.ZRange(cp.ctx, key, start, stop).Result()
}

func (cp *CacheProxy) Expire(key string, ttl time.Duration) error {
	return cp.client.Expire(cp.ctx, key, ttl).Err()
}

func (cp *CacheProxy) TTL(key string) (time.Duration, error) {
	return cp.client.TTL(cp.ctx, key).Result()
}

func (cp *CacheProxy) FlushDB() error {
	return cp.client.FlushDB(cp.ctx).Err()
}

func (cp *CacheProxy) GetWithFallback(key string, fallback func() (interface{}, error), ttl time.Duration) (interface{}, error) {
	val, err := cp.Get(key)
	if err == nil {
		return val, nil
	}

	result, err := fallback()
	if err != nil {
		return nil, err
	}

	cp.Set(key, result, ttl)
	return result, nil
}

func (cp *CacheProxy) Close() error {
	return cp.client.Close()
}

type CacheStats struct {
	Hits          int64
	Misses        int64
	Keys          int64
	MemoryUsage   int64
	ConnectedClients int
}

func (cp *CacheProxy) GetStats() (*CacheStats, error) {
	info, err := cp.client.Info(cp.ctx).Result()
	if err != nil {
		return nil, err
	}

	dbSize, _ := cp.client.DBSize(cp.ctx).Result()

	return &CacheStats{
		Keys: dbSize,
	}, nil
}

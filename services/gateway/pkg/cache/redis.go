package cache

import (
	"context"
	"time"

	"github.com/go-redis/redis/v8"
)

type RedisCache struct {
	client *redis.Client
	ctx    context.Context
}

func NewRedisCache(addr string) *RedisCache {
	client := redis.NewClient(&redis.Options{
		Addr: addr,
		DB:   0,
	})

	return &RedisCache{
		client: client,
		ctx:    context.Background(),
	}
}

func (r *RedisCache) Set(key string, value interface{}, expiration time.Duration) error {
	return r.client.Set(r.ctx, key, value, expiration).Err()
}

func (r *RedisCache) Get(key string) (string, error) {
	return r.client.Get(r.ctx, key).Result()
}

func (r *RedisCache) Delete(key string) error {
	return r.client.Del(r.ctx, key).Err()
}

func (r *RedisCache) Exists(key string) (bool, error) {
	result, err := r.client.Exists(r.ctx, key).Result()
	return result > 0, err
}

func (r *RedisCache) Close() error {
	return r.client.Close()
}

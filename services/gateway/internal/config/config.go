package config

import (
	"os"
)

type Config struct {
	Port          string
	AuthServiceURL string
	UserServiceURL string
	RedisURL      string
	Environment   string
}

func Load() *Config {
	return &Config{
		Port:          getEnv("PORT", ":8000"),
		AuthServiceURL: getEnv("AUTH_SERVICE_URL", "http://localhost:8001"),
		UserServiceURL: getEnv("USER_SERVICE_URL", "http://localhost:8002"),
		RedisURL:      getEnv("REDIS_URL", "localhost:6379"),
		Environment:   getEnv("ENVIRONMENT", "development"),
	}
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

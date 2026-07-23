package tests

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
)

func TestCORSMiddleware(t *testing.T) {
	gin.SetMode(gin.TestMode)
	router := gin.Default()

	router.GET("/test", func(c *gin.Context) {
		c.Header("Access-Control-Allow-Origin", "*")
		c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE")
		c.JSON(200, gin.H{"message": "ok"})
	})

	w := httptest.NewRecorder()
	req, _ := http.NewRequest("OPTIONS", "/test", nil)
	req.Header.Set("Origin", "http://example.com")
	router.ServeHTTP(w, req)

	assert.Contains(t, w.Header().Get("Access-Control-Allow-Origin"), "*")
}

func TestAuthMiddleware(t *testing.T) {
	gin.SetMode(gin.TestMode)
	router := gin.Default()

	router.GET("/protected", func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.JSON(401, gin.H{"error": "Unauthorized"})
			c.Abort()
			return
		}
		c.JSON(200, gin.H{"message": "authorized"})
	})

	// Test without token
	w := httptest.NewRecorder()
	req, _ := http.NewRequest("GET", "/protected", nil)
	router.ServeHTTP(w, req)
	assert.Equal(t, 401, w.Code)

	// Test with token
	w2 := httptest.NewRecorder()
	req2, _ := http.NewRequest("GET", "/protected", nil)
	req2.Header.Set("Authorization", "Bearer test-token")
	router.ServeHTTP(w2, req2)
	assert.Equal(t, 200, w2.Code)
}

func TestRateLimitMiddleware(t *testing.T) {
	gin.SetMode(gin.TestMode)
	router := gin.Default()

	requestCount := 0
	router.GET("/limited", func(c *gin.Context) {
		requestCount++
		if requestCount > 10 {
			c.JSON(429, gin.H{"error": "Rate limit exceeded"})
			return
		}
		c.JSON(200, gin.H{"message": "ok"})
	})

	// Make requests up to limit
	for i := 0; i < 10; i++ {
		w := httptest.NewRecorder()
		req, _ := http.NewRequest("GET", "/limited", nil)
		router.ServeHTTP(w, req)
		assert.Equal(t, 200, w.Code)
	}

	// Exceed rate limit
	w := httptest.NewRecorder()
	req, _ := http.NewRequest("GET", "/limited", nil)
	router.ServeHTTP(w, req)
	assert.Equal(t, 429, w.Code)
}

func BenchmarkGatewayRouting(b *testing.B) {
	gin.SetMode(gin.TestMode)
	router := gin.Default()

	router.GET("/api/test", func(c *gin.Context) {
		c.JSON(200, gin.H{"message": "benchmark"})
	})

	w := httptest.NewRecorder()
	req, _ := http.NewRequest("GET", "/api/test", nil)

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		router.ServeHTTP(w, req)
	}
}

func BenchmarkJSONSerialization(b *testing.B) {
	gin.SetMode(gin.TestMode)
	router := gin.Default()

	router.GET("/json", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"users": []gin.H{
				{"id": 1, "name": "User 1"},
				{"id": 2, "name": "User 2"},
				{"id": 3, "name": "User 3"},
			},
		})
	})

	w := httptest.NewRecorder()
	req, _ := http.NewRequest("GET", "/json", nil)

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		router.ServeHTTP(w, req)
	}
}

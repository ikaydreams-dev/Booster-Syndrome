package routes

import (
	"github.com/gin-gonic/gin"
	"net/http"
	"net/http/httputil"
	"net/url"
	"time"
)

type ServiceConfig struct {
	Name string
	URL  string
}

var services = map[string]string{
	"auth":         "http://auth-service:3000",
	"users":        "http://user-service:3001",
	"analytics":    "http://analytics-service:8001",
	"notifications": "http://notification-service:4001",
	"files":        "http://file-service:5000",
	"chat":         "http://chat-service:4000",
}

func SetupRoutes(r *gin.Engine) {
	// Health check
	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"status":    "healthy",
			"timestamp": time.Now().Unix(),
		})
	})

	// API version group
	v1 := r.Group("/api/v1")
	{
		// Auth routes
		v1.POST("/auth/login", proxyTo("auth", "/api/v1/auth/login"))
		v1.POST("/auth/register", proxyTo("auth", "/api/v1/auth/register"))
		v1.POST("/auth/logout", proxyTo("auth", "/api/v1/auth/logout"))
		v1.POST("/auth/refresh", proxyTo("auth", "/api/v1/auth/refresh"))

		// User routes (protected)
		v1.GET("/users", proxyTo("users", "/api/v1/users"))
		v1.GET("/users/:id", proxyTo("users", "/api/v1/users/:id"))
		v1.PUT("/users/:id", proxyTo("users", "/api/v1/users/:id"))
		v1.DELETE("/users/:id", proxyTo("users", "/api/v1/users/:id"))

		// Analytics routes
		v1.POST("/analytics/events", proxyTo("analytics", "/api/v1/analytics/events"))
		v1.GET("/analytics/summary", proxyTo("analytics", "/api/v1/analytics/summary"))

		// File routes
		v1.POST("/files/upload", proxyTo("files", "/api/v1/files/upload"))
		v1.GET("/files/:id", proxyTo("files", "/api/v1/files/:id"))

		// Chat routes
		v1.GET("/chat/rooms", proxyTo("chat", "/api/v1/chat/rooms"))
		v1.POST("/chat/messages", proxyTo("chat", "/api/v1/chat/messages"))
	}
}

func proxyTo(serviceName, path string) gin.HandlerFunc {
	return func(c *gin.Context) {
		serviceURL, exists := services[serviceName]
		if !exists {
			c.JSON(http.StatusNotFound, gin.H{"error": "Service not found"})
			return
		}

		remote, err := url.Parse(serviceURL)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Invalid service URL"})
			return
		}

		proxy := httputil.NewSingleHostReverseProxy(remote)
		proxy.Director = func(req *http.Request) {
			req.Header = c.Request.Header
			req.Host = remote.Host
			req.URL.Scheme = remote.Scheme
			req.URL.Host = remote.Host
			req.URL.Path = c.Param("*")
		}

		proxy.ServeHTTP(c.Writer, c.Request)
	}
}

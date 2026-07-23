package handlers

import (
	"bytes"
	"io"
	"net/http"

	"github.com/gin-gonic/gin"
)

func ProxyToAuthService(c *gin.Context) {
	proxyRequest(c, "http://localhost:8001")
}

func ProxyToUserService(c *gin.Context) {
	proxyRequest(c, "http://localhost:8002")
}

func proxyRequest(c *gin.Context, targetURL string) {
	body, _ := io.ReadAll(c.Request.Body)

	req, err := http.NewRequest(c.Request.Method, targetURL+c.Request.URL.Path, bytes.NewBuffer(body))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create request"})
		return
	}

	for key, values := range c.Request.Header {
		for _, value := range values {
			req.Header.Add(key, value)
		}
	}

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		c.JSON(http.StatusBadGateway, gin.H{"error": "Service unavailable"})
		return
	}
	defer resp.Body.Close()

	respBody, _ := io.ReadAll(resp.Body)
	c.Data(resp.StatusCode, resp.Header.Get("Content-Type"), respBody)
}

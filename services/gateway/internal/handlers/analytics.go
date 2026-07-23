package handlers

import "github.com/gin-gonic/gin"

const analyticsServiceURL = "http://localhost:8003"

func TrackEvent(c *gin.Context) {
	proxyToService(c, analyticsServiceURL+"/api/v1/analytics/events")
}

func GetStats(c *gin.Context) {
	proxyToService(c, analyticsServiceURL+"/api/v1/stats/summary")
}

func GetDailyStats(c *gin.Context) {
	proxyToService(c, analyticsServiceURL+"/api/v1/stats/daily")
}

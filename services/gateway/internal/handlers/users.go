package handlers

import (
	"bytes"
	"io"
	"net/http"

	"github.com/gin-gonic/gin"
)

const userServiceURL = "http://localhost:8002"

func GetUser(c *gin.Context) {
	userID := c.Param("id")
	proxyToService(c, userServiceURL+"/api/v1/users/"+userID)
}

func UpdateUser(c *gin.Context) {
	userID := c.Param("id")
	proxyToService(c, userServiceURL+"/api/v1/users/"+userID)
}

func DeleteUser(c *gin.Context) {
	userID := c.Param("id")
	proxyToService(c, userServiceURL+"/api/v1/users/"+userID)
}

func ListUsers(c *gin.Context) {
	proxyToService(c, userServiceURL+"/api/v1/users")
}

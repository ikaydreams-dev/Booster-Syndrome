package middleware

import (
	"log"
	"net/http"
	"runtime/debug"

	"github.com/gin-gonic/gin"
)

type ErrorResponse struct {
	Error   string `json:"error"`
	Message string `json:"message"`
	Code    int    `json:"code"`
}

func ErrorHandler() gin.HandlerFunc {
	return func(c *gin.Context) {
		defer func() {
			if err := recover(); err != nil {
				log.Printf("Panic recovered: %v\n%s", err, debug.Stack())

				c.JSON(http.StatusInternalServerError, ErrorResponse{
					Error:   "Internal Server Error",
					Message: "An unexpected error occurred",
					Code:    http.StatusInternalServerError,
				})

				c.Abort()
			}
		}()

		c.Next()

		if len(c.Errors) > 0 {
			err := c.Errors.Last()

			status := http.StatusInternalServerError
			message := err.Error()

			if c.Writer.Status() != http.StatusOK {
				status = c.Writer.Status()
			}

			c.JSON(status, ErrorResponse{
				Error:   http.StatusText(status),
				Message: message,
				Code:    status,
			})
		}
	}
}

func NotFoundHandler() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.JSON(http.StatusNotFound, ErrorResponse{
			Error:   "Not Found",
			Message: "The requested resource was not found",
			Code:    http.StatusNotFound,
		})
	}
}

func ValidationErrorHandler(err error) ErrorResponse {
	return ErrorResponse{
		Error:   "Validation Error",
		Message: err.Error(),
		Code:    http.StatusBadRequest,
	}
}

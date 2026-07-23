package routes

import (
	"github.com/gin-gonic/gin"
	"go.uber.org/zap"

	"github.com/ikaydreams-dev/booster-syndrome/gateway/internal/handlers"
)

func SetupRoutes(router *gin.Engine, logger *zap.Logger) {
	v1 := router.Group("/api/v1")
	{
		auth := v1.Group("/auth")
		{
			auth.POST("/register", handlers.ProxyToAuthService)
			auth.POST("/login", handlers.ProxyToAuthService)
			auth.POST("/refresh", handlers.ProxyToAuthService)
			auth.POST("/logout", handlers.ProxyToAuthService)
		}

		users := v1.Group("/users")
		{
			users.GET("/:id", handlers.ProxyToUserService)
			users.PUT("/:id", handlers.ProxyToUserService)
			users.DELETE("/:id", handlers.ProxyToUserService)
		}
	}
}

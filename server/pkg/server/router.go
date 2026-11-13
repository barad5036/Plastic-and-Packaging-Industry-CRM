package server

import (
	"log"
	"net/http"
	"os"
	"strings"
	"sync"

	"crm-server/internal/auth"
	"crm-server/internal/dashboard"
	"crm-server/internal/dealers"
	"crm-server/internal/deals"
	"crm-server/internal/leads"
	"crm-server/internal/quotes"
	"crm-server/internal/tasks"
	"crm-server/pkg/database"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
)

var (
	router *gin.Engine
	once   sync.Once
)

func NewRouter() *gin.Engine {
	once.Do(func() {
		if err := godotenv.Load(); err != nil {
			log.Println("No .env file found, using environment variables")
		}

		database.ConnectDB()
		router = gin.Default()
		router.Use(cors.New(buildCorsConfig()))
		registerRoutes(router)
	})

	return router
}

func buildCorsConfig() cors.Config {
	allowedOrigins := []string{"*"}
	allowCredentials := false

	if origins := strings.TrimSpace(os.Getenv("CORS_ALLOWED_ORIGINS")); origins != "" {
		allowedOrigins = strings.Split(origins, ",")
		for i, origin := range allowedOrigins {
			allowedOrigins[i] = strings.TrimSpace(origin)
		}
		allowCredentials = len(allowedOrigins) > 0 && !(len(allowedOrigins) == 1 && allowedOrigins[0] == "*")
	}

	return cors.Config{
		AllowOrigins:     allowedOrigins,
		AllowMethods:     []string{"GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"},
		AllowHeaders:     []string{"Origin", "Content-Type", "Accept", "Authorization"},
		ExposeHeaders:    []string{"Content-Length"},
		AllowCredentials: allowCredentials,
	}
}

func registerRoutes(router *gin.Engine) {
	router.GET("/", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"name":    "SalesHub CRM API",
			"status":  "ok",
			"message": "Backend is running",
		})
	})

	router.GET("/health", func(c *gin.Context) {
		status := "ok"
		databaseStatus := "connected"
		if !database.IsConnected() {
			status = "degraded"
			databaseStatus = "disconnected"
		}

		c.JSON(http.StatusOK, gin.H{
			"status":   status,
			"database": databaseStatus,
		})
	})

	authGroup := router.Group("/auth")
	authGroup.Use(requireDatabase())
	{
		authGroup.POST("/register", auth.Register)
		authGroup.POST("/login", auth.Login)
	}

	api := router.Group("/api")
	api.Use(requireDatabase())
	api.Use(auth.AuthMiddleware())
	{
		api.GET("/dashboard/summary", dashboard.GetSummary)

		api.GET("/leads", leads.GetLeads)
		api.POST("/leads", leads.CreateLead)
		api.POST("/leads/import", leads.BulkImportLeads)
		api.PUT("/leads/:id", leads.UpdateLead)
		api.DELETE("/leads/:id", leads.DeleteLead)
		api.DELETE("/leads", leads.ClearAllLeads)

		api.GET("/deals", deals.GetDeals)
		api.POST("/deals", deals.CreateDeal)
		api.PUT("/deals/:id", deals.UpdateDeal)
		api.DELETE("/deals/:id", deals.DeleteDeal)

		api.GET("/tasks", tasks.GetTasks)
		api.POST("/tasks", tasks.CreateTask)
		api.PUT("/tasks/:id", tasks.UpdateTask)
		api.DELETE("/tasks/:id", tasks.DeleteTask)

		api.GET("/quotes", quotes.GetQuotations)
		api.GET("/quotes/:id", quotes.GetQuotation)
		api.POST("/quotes", quotes.CreateQuotation)
		api.PUT("/quotes/:id", quotes.UpdateQuotation)
		api.DELETE("/quotes/:id", quotes.DeleteQuotation)

		api.GET("/dealers", dealers.GetDealers)
		api.GET("/dealers/:id", dealers.GetDealer)
		api.POST("/dealers", dealers.CreateDealer)
		api.PUT("/dealers/:id", dealers.UpdateDealer)
		api.DELETE("/dealers/:id", dealers.DeleteDealer)
	}
}

func requireDatabase() gin.HandlerFunc {
	return func(c *gin.Context) {
		if !database.IsConnected() {
			c.JSON(http.StatusServiceUnavailable, gin.H{
				"error": "Database is not configured for this deployment",
			})
			c.Abort()
			return
		}

		c.Next()
	}
}

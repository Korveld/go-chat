package main

import (
	"log"
	"os"

	"chat-backend/config"
	"chat-backend/database"
	"chat-backend/routes"

	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
)

func main() {
	// Load environment variables
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found")
	}

	// Initialize database
	database.Connect()
	database.Migrate()

	// Start background tasks (cleanup expired tokens)
	database.StartBackgroundTasks()

	// Initialize WebSocket hub
	hub := routes.NewHub()
	go hub.Run()

	// Setup router
	router := gin.Default()

	// CORS middleware
	router.Use(config.CORSMiddleware())

	// Health check
	router.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "ok"})
	})

	// API routes
	api := router.Group("/api/v1")
	{
		// Auth routes
		auth := api.Group("/auth")
		{
			auth.POST("/register", routes.Register)
			auth.POST("/login", routes.Login)
		}

		// Protected routes
		protected := api.Group("/")
		protected.Use(config.AuthMiddleware())
		{
			// Auth routes (protected)
			protected.POST("/auth/logout", routes.Logout)

			// User routes
			protected.GET("/users/me", routes.GetCurrentUser)
			protected.GET("/users", routes.GetUsers)

			// Conversation routes
			protected.POST("/conversations", routes.CreateConversation)
			protected.GET("/conversations", routes.GetConversations)
			protected.GET("/conversations/:id/messages", routes.GetMessages)

			// WebSocket
			protected.GET("/ws", func(c *gin.Context) {
				routes.ServeWs(hub, c)
			})
		}
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("Server starting on port %s", port)
	router.Run(":" + port)
}

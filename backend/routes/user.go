package routes

import (
	"net/http"

	"chat-backend/database"
	"chat-backend/models"

	"github.com/gin-gonic/gin"
)

func GetCurrentUser(c *gin.Context) {
	user, exists := c.Get("user")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "User not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"user": user})
}

func GetUsers(c *gin.Context) {
	currentUser, _ := c.Get("user")
	currentUserData := currentUser.(models.User)

	var users []models.User
	if err := database.DB.Where("id != ?", currentUserData.ID).Find(&users).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch users"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"users": users})
}

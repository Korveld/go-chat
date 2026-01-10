package database

import (
	"log"
	"time"

	"chat-backend/models"
)

// CleanupExpiredTokens removes expired tokens from blacklist
func CleanupExpiredTokens() {
	ticker := time.NewTicker(1 * time.Hour) // Run every hour
	defer ticker.Stop()

	for range ticker.C {
		result := DB.Where("expires_at < ?", time.Now()).Delete(&models.TokenBlacklist{})
		if result.Error != nil {
			log.Printf("Error cleaning up expired tokens: %v", result.Error)
		} else if result.RowsAffected > 0 {
			log.Printf("Cleaned up %d expired tokens", result.RowsAffected)
		}
	}
}

// StartBackgroundTasks starts all background tasks
func StartBackgroundTasks() {
	go CleanupExpiredTokens()
	log.Println("Background tasks started")
}

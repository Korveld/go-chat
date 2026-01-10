package main

import (
	"fmt"
	"log"
	"strings"
	"time"

	"chat-backend/database"
	"chat-backend/models"

	"github.com/joho/godotenv"
)

func main() {
	// Load environment variables
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found")
	}

	// Connect to database
	database.Connect()

	log.Println("Starting database seeding...")

	// Create sample users
	users := []models.User{
		{
			Username: "alice",
			Email:    "alice@example.com",
			Phone:    "+1234567890",
			Status:   "online",
			LastSeen: time.Now(),
		},
		{
			Username: "bob",
			Email:    "bob@example.com",
			Phone:    "+1234567891",
			Status:   "online",
			LastSeen: time.Now(),
		},
		{
			Username: "charlie",
			Email:    "charlie@example.com",
			Phone:    "+1234567892",
			Status:   "offline",
			LastSeen: time.Now().Add(-1 * time.Hour),
		},
		{
			Username: "diana",
			Email:    "diana@example.com",
			Phone:    "+1234567893",
			Status:   "online",
			LastSeen: time.Now(),
		},
	}

	// Hash password for all users
	password := "password123"
	for i := range users {
		if err := users[i].HashPassword(password); err != nil {
			log.Fatal("Failed to hash password:", err)
		}
		if err := database.DB.Create(&users[i]).Error; err != nil {
			log.Printf("User %s already exists, skipping", users[i].Username)
		} else {
			log.Printf("✓ Created user: %s", users[i].Username)
		}
	}

	// Reload users to get IDs
	database.DB.Find(&users)

	// Create direct conversations
	if len(users) >= 2 {
		// Alice <-> Bob
		conv1 := models.Conversation{
			Type:      models.DirectMessage,
			CreatedBy: users[0].ID,
		}
		if err := database.DB.Create(&conv1).Error; err == nil {
			database.DB.Model(&conv1).Association("Participants").Append([]models.User{users[0], users[1]})
			log.Printf("✓ Created conversation between %s and %s", users[0].Username, users[1].Username)

			// Add messages
			messages := []models.Message{
				{
					ConversationID: conv1.ID,
					SenderID:       users[0].ID,
					Content:        "Hey Bob! How are you?",
					Type:           models.TextMessage,
					Status:         models.MessageRead,
					CreatedAt:      time.Now().Add(-2 * time.Hour),
				},
				{
					ConversationID: conv1.ID,
					SenderID:       users[1].ID,
					Content:        "Hi Alice! I'm doing great, thanks!",
					Type:           models.TextMessage,
					Status:         models.MessageRead,
					CreatedAt:      time.Now().Add(-1 * time.Hour),
				},
				{
					ConversationID: conv1.ID,
					SenderID:       users[0].ID,
					Content:        "That's awesome! Want to grab coffee later?",
					Type:           models.TextMessage,
					Status:         models.MessageDelivered,
					CreatedAt:      time.Now().Add(-30 * time.Minute),
				},
			}
			database.DB.Create(&messages)
			log.Printf("✓ Added %d messages to conversation", len(messages))
		}

		// Alice <-> Charlie
		conv2 := models.Conversation{
			Type:      models.DirectMessage,
			CreatedBy: users[0].ID,
		}
		if err := database.DB.Create(&conv2).Error; err == nil {
			database.DB.Model(&conv2).Association("Participants").Append([]models.User{users[0], users[2]})
			log.Printf("✓ Created conversation between %s and %s", users[0].Username, users[2].Username)

			messages := []models.Message{
				{
					ConversationID: conv2.ID,
					SenderID:       users[0].ID,
					Content:        "Charlie, are you coming to the meeting?",
					Type:           models.TextMessage,
					Status:         models.MessageSent,
					CreatedAt:      time.Now().Add(-15 * time.Minute),
				},
			}
			database.DB.Create(&messages)
			log.Printf("✓ Added %d messages to conversation", len(messages))
		}
	}

	// Create a group conversation
	if len(users) >= 3 {
		groupConv := models.Conversation{
			Type:      models.GroupChat,
			Name:      "Team Chat",
			CreatedBy: users[0].ID,
		}
		if err := database.DB.Create(&groupConv).Error; err == nil {
			database.DB.Model(&groupConv).Association("Participants").Append([]models.User{users[0], users[1], users[2], users[3]})
			log.Printf("✓ Created group conversation: %s", groupConv.Name)

			messages := []models.Message{
				{
					ConversationID: groupConv.ID,
					SenderID:       users[0].ID,
					Content:        "Welcome to the team chat!",
					Type:           models.TextMessage,
					Status:         models.MessageRead,
					CreatedAt:      time.Now().Add(-3 * time.Hour),
				},
				{
					ConversationID: groupConv.ID,
					SenderID:       users[1].ID,
					Content:        "Thanks! Happy to be here 🎉",
					Type:           models.TextMessage,
					Status:         models.MessageRead,
					CreatedAt:      time.Now().Add(-2 * time.Hour),
				},
				{
					ConversationID: groupConv.ID,
					SenderID:       users[3].ID,
					Content:        "Let's have a productive week!",
					Type:           models.TextMessage,
					Status:         models.MessageDelivered,
					CreatedAt:      time.Now().Add(-1 * time.Hour),
				},
			}
			database.DB.Create(&messages)
			log.Printf("✓ Added %d messages to group", len(messages))
		}
	}

	fmt.Println("\n" + strings.Repeat("=", 50))
	log.Println("✓ Database seeded successfully!")
	log.Println("\nSample users (all have password: password123):")
	for _, user := range users {
		log.Printf("  - %s (%s)", user.Username, user.Email)
	}
	fmt.Println(strings.Repeat("=", 50))
}

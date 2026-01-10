package routes

import (
	"net/http"

	"chat-backend/database"
	"chat-backend/models"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

type CreateConversationInput struct {
	Type           string `json:"type" binding:"required,oneof=direct group"`
	Name           string `json:"name"`
	ParticipantID  uint   `json:"participant_id"`  // For direct messages
	ParticipantIDs []uint `json:"participant_ids"` // For group chats
}

func CreateConversation(c *gin.Context) {
	currentUser, _ := c.Get("user")
	user := currentUser.(models.User)

	var input CreateConversationInput
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// For direct messages, check if conversation already exists
	if input.Type == "direct" {
		var existingConv models.Conversation
		err := database.DB.
			Joins("JOIN conversation_participants cp1 ON cp1.conversation_id = conversations.id").
			Joins("JOIN conversation_participants cp2 ON cp2.conversation_id = conversations.id").
			Where("conversations.type = ?", "direct").
			Where("cp1.user_id = ? AND cp2.user_id = ?", user.ID, input.ParticipantID).
			First(&existingConv).Error

		if err == nil {
			// Conversation exists, return it with participants
			database.DB.Preload("Participants").First(&existingConv, existingConv.ID)
			c.JSON(http.StatusOK, gin.H{"conversation": existingConv})
			return
		}
	}

	conversation := models.Conversation{
		Type:      models.ConversationType(input.Type),
		Name:      input.Name,
		CreatedBy: user.ID,
	}

	if err := database.DB.Create(&conversation).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create conversation"})
		return
	}

	// Add participants
	var participants []models.User
	participants = append(participants, user) // Add creator

	if input.Type == "direct" && input.ParticipantID != 0 {
		var otherUser models.User
		if err := database.DB.First(&otherUser, input.ParticipantID).Error; err == nil {
			participants = append(participants, otherUser)
		}
	} else if input.Type == "group" && len(input.ParticipantIDs) > 0 {
		database.DB.Where("id IN ?", input.ParticipantIDs).Find(&participants)
	}

	database.DB.Model(&conversation).Association("Participants").Append(participants)

	// Load participants for response
	database.DB.Preload("Participants").First(&conversation, conversation.ID)

	c.JSON(http.StatusCreated, gin.H{"conversation": conversation})
}

func GetConversations(c *gin.Context) {
	currentUser, _ := c.Get("user")
	user := currentUser.(models.User)

	var conversations []models.Conversation
	err := database.DB.
		Joins("JOIN conversation_participants ON conversation_participants.conversation_id = conversations.id").
		Where("conversation_participants.user_id = ?", user.ID).
		Preload("Participants").
		Preload("Messages", func(db *gorm.DB) *gorm.DB {
			return db.Order("created_at DESC").Limit(1)
		}).
		Preload("Messages.Sender").
		Order("conversations.updated_at DESC").
		Find(&conversations).Error

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch conversations"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"conversations": conversations})
}

func GetMessages(c *gin.Context) {
	conversationID := c.Param("id")
	currentUser, _ := c.Get("user")
	user := currentUser.(models.User)

	// Verify user is participant
	var conversation models.Conversation
	err := database.DB.
		Joins("JOIN conversation_participants ON conversation_participants.conversation_id = conversations.id").
		Where("conversations.id = ? AND conversation_participants.user_id = ?", conversationID, user.ID).
		First(&conversation).Error

	if err != nil {
		c.JSON(http.StatusForbidden, gin.H{"error": "Access denied"})
		return
	}

	var messages []models.Message
	if err := database.DB.
		Where("conversation_id = ?", conversationID).
		Preload("Sender").
		Preload("ReplyTo").
		Order("created_at ASC").
		Find(&messages).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch messages"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"messages": messages})
}

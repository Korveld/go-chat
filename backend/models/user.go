package models

import (
	"time"

	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

type User struct {
	ID        uint      `gorm:"primaryKey" json:"id"`
	Username  string    `gorm:"unique;not null" json:"username"`
	Email     string    `gorm:"unique;not null" json:"email"`
	Password  string    `gorm:"not null" json:"-"`
	Phone     string    `gorm:"unique" json:"phone,omitempty"`
	Avatar    string    `json:"avatar,omitempty"`
	Status    string    `gorm:"default:'offline'" json:"status"`
	LastSeen  time.Time `json:"last_seen"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

func (u *User) HashPassword(password string) error {
	bytes, err := bcrypt.GenerateFromPassword([]byte(password), 14)
	if err != nil {
		return err
	}
	u.Password = string(bytes)
	return nil
}

func (u *User) CheckPassword(password string) error {
	return bcrypt.CompareHashAndPassword([]byte(u.Password), []byte(password))
}

// models/conversation.go
type ConversationType string

const (
	DirectMessage ConversationType = "direct"
	GroupChat     ConversationType = "group"
)

type Conversation struct {
	ID           uint             `gorm:"primaryKey" json:"id"`
	Type         ConversationType `gorm:"not null" json:"type"`
	Name         string           `json:"name,omitempty"`
	Avatar       string           `json:"avatar,omitempty"`
	CreatedBy    uint             `json:"created_by"`
	Creator      User             `gorm:"foreignKey:CreatedBy" json:"creator,omitempty"`
	Participants []User           `gorm:"many2many:conversation_participants;" json:"participants,omitempty"`
	Messages     []Message        `gorm:"foreignKey:ConversationID" json:"messages,omitempty"`
	CreatedAt    time.Time        `json:"created_at"`
	UpdatedAt    time.Time        `json:"updated_at"`
}

// models/message.go
type MessageType string

const (
	TextMessage  MessageType = "text"
	ImageMessage MessageType = "image"
	VideoMessage MessageType = "video"
	AudioMessage MessageType = "audio"
	FileMessage  MessageType = "file"
)

type MessageStatus string

const (
	MessageSent      MessageStatus = "sent"
	MessageDelivered MessageStatus = "delivered"
	MessageRead      MessageStatus = "read"
)

type Message struct {
	ID             uint           `gorm:"primaryKey" json:"id"`
	ConversationID uint           `gorm:"not null;index" json:"conversation_id"`
	SenderID       uint           `gorm:"not null;index" json:"sender_id"`
	Sender         User           `gorm:"foreignKey:SenderID" json:"sender,omitempty"`
	Content        string         `gorm:"type:text" json:"content"`
	Type           MessageType    `gorm:"default:'text'" json:"type"`
	Status         MessageStatus  `gorm:"default:'sent'" json:"status"`
	MediaURL       string         `json:"media_url,omitempty"`
	ReplyToID      *uint          `json:"reply_to_id,omitempty"`
	ReplyTo        *Message       `gorm:"foreignKey:ReplyToID" json:"reply_to,omitempty"`
	CreatedAt      time.Time      `json:"created_at"`
	UpdatedAt      time.Time      `json:"updated_at"`
	DeletedAt      gorm.DeletedAt `gorm:"index" json:"-"`
}

// models/token_blacklist.go
type TokenBlacklist struct {
	ID        uint      `gorm:"primaryKey" json:"id"`
	Token     string    `gorm:"uniqueIndex;not null" json:"token"`
	UserID    uint      `gorm:"index" json:"user_id"`
	ExpiresAt time.Time `gorm:"index" json:"expires_at"`
	CreatedAt time.Time `json:"created_at"`
}

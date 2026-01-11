package routes

import (
	"encoding/json"
	"log"
	"net/http"
	"time"

	"chat-backend/database"
	"chat-backend/models"

	"github.com/gin-gonic/gin"
	"github.com/gorilla/websocket"
)

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin: func(r *http.Request) bool {
		return true // Allow all origins for now
	},
}

type Client struct {
	hub    *Hub
	conn   *websocket.Conn
	send   chan []byte
	userID uint
}

type Hub struct {
	clients     map[*Client]bool
	broadcast   chan []byte
	register    chan *Client
	unregister  chan *Client
	userClients map[uint]*Client // Map user ID to client
}

type WSMessage struct {
	Type           string `json:"type"`
	ConversationID uint   `json:"conversation_id"`
	Content        string `json:"content"`
	MessageType    string `json:"message_type,omitempty"`
	ReplyToID      *uint  `json:"reply_to_id,omitempty"`
}

func NewHub() *Hub {
	return &Hub{
		broadcast:   make(chan []byte),
		register:    make(chan *Client),
		unregister:  make(chan *Client),
		clients:     make(map[*Client]bool),
		userClients: make(map[uint]*Client),
	}
}

func (h *Hub) Run() {
	for {
		select {
		case client := <-h.register:
			h.clients[client] = true
			h.userClients[client.userID] = client
			log.Printf("Client connected: User ID %d", client.userID)

			// Set user online
			database.DB.Model(&models.User{}).Where("id = ?", client.userID).
				Updates(map[string]interface{}{"status": "online", "last_seen": time.Now()})

			// Broadcast status change to all clients
			h.broadcastStatusChange(client.userID, "online")

		case client := <-h.unregister:
			if _, ok := h.clients[client]; ok {
				delete(h.clients, client)
				delete(h.userClients, client.userID)
				close(client.send)
				log.Printf("Client disconnected: User ID %d", client.userID)

				// Set user offline
				database.DB.Model(&models.User{}).Where("id = ?", client.userID).
					Updates(map[string]interface{}{"status": "offline", "last_seen": time.Now()})

				// Broadcast status change to all clients
				h.broadcastStatusChange(client.userID, "offline")
			}

		case message := <-h.broadcast:
			for client := range h.clients {
				select {
				case client.send <- message:
				default:
					close(client.send)
					delete(h.clients, client)
					delete(h.userClients, client.userID)
				}
			}
		}
	}
}

func (h *Hub) broadcastStatusChange(userID uint, status string) {
	statusMsg, _ := json.Marshal(map[string]interface{}{
		"type":    "status_change",
		"user_id": userID,
		"status":  status,
	})

	for client := range h.clients {
		select {
		case client.send <- statusMsg:
		default:
		}
	}
}

func (c *Client) readPump() {
	defer func() {
		c.hub.unregister <- c
		c.conn.Close()
	}()

	c.conn.SetReadDeadline(time.Now().Add(60 * time.Second))
	c.conn.SetPongHandler(func(string) error {
		c.conn.SetReadDeadline(time.Now().Add(60 * time.Second))
		return nil
	})

	for {
		_, message, err := c.conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
				log.Printf("error: %v", err)
			}
			break
		}

		var wsMsg WSMessage
		if err := json.Unmarshal(message, &wsMsg); err != nil {
			log.Printf("Invalid message format: %v", err)
			continue
		}

		switch wsMsg.Type {
		case "message":
			c.handleNewMessage(wsMsg)
		case "typing":
			c.handleTyping(wsMsg)
		}
	}
}

func (c *Client) writePump() {
	ticker := time.NewTicker(54 * time.Second)
	defer func() {
		ticker.Stop()
		c.conn.Close()
	}()

	for {
		select {
		case message, ok := <-c.send:
			c.conn.SetWriteDeadline(time.Now().Add(10 * time.Second))
			if !ok {
				c.conn.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}

			w, err := c.conn.NextWriter(websocket.TextMessage)
			if err != nil {
				return
			}
			w.Write(message)

			if err := w.Close(); err != nil {
				return
			}

		case <-ticker.C:
			c.conn.SetWriteDeadline(time.Now().Add(10 * time.Second))
			if err := c.conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}
		}
	}
}

func (c *Client) handleNewMessage(wsMsg WSMessage) {
	// Save message to database
	msgType := models.TextMessage
	if wsMsg.MessageType != "" {
		msgType = models.MessageType(wsMsg.MessageType)
	}

	message := models.Message{
		ConversationID: wsMsg.ConversationID,
		SenderID:       c.userID,
		Content:        wsMsg.Content,
		Type:           msgType,
		Status:         models.MessageSent,
		ReplyToID:      wsMsg.ReplyToID,
	}

	if err := database.DB.Create(&message).Error; err != nil {
		log.Printf("Failed to save message: %v", err)
		return
	}

	// Load sender info
	database.DB.Preload("Sender").First(&message, message.ID)

	// Update conversation timestamp
	database.DB.Model(&models.Conversation{}).
		Where("id = ?", wsMsg.ConversationID).
		Update("updated_at", time.Now())

	// Broadcast to all participants
	var conversation models.Conversation
	database.DB.Preload("Participants").First(&conversation, wsMsg.ConversationID)

	responseMsg, _ := json.Marshal(map[string]interface{}{
		"type":    "new_message",
		"message": message,
	})

	for _, participant := range conversation.Participants {
		if client, ok := c.hub.userClients[participant.ID]; ok {
			select {
			case client.send <- responseMsg:
			default:
				close(client.send)
				delete(c.hub.clients, client)
			}
		}
	}
}

func (c *Client) handleTyping(wsMsg WSMessage) {
	// Broadcast typing indicator to other participants
	var conversation models.Conversation
	database.DB.Preload("Participants").First(&conversation, wsMsg.ConversationID)

	responseMsg, _ := json.Marshal(map[string]interface{}{
		"type":            "typing",
		"conversation_id": wsMsg.ConversationID,
		"user_id":         c.userID,
	})

	for _, participant := range conversation.Participants {
		if participant.ID != c.userID {
			if client, ok := c.hub.userClients[participant.ID]; ok {
				select {
				case client.send <- responseMsg:
				default:
				}
			}
		}
	}
}

func ServeWs(hub *Hub, c *gin.Context) {
	currentUser, _ := c.Get("user")
	user := currentUser.(models.User)

	conn, err := upgrader.Upgrade(c.Writer, c.Request, nil)
	if err != nil {
		log.Println(err)
		return
	}

	client := &Client{
		hub:    hub,
		conn:   conn,
		send:   make(chan []byte, 256),
		userID: user.ID,
	}

	client.hub.register <- client

	go client.writePump()
	go client.readPump()
}

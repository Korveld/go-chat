# Chat App Backend - Go + Gin + PostgreSQL

A production-ready real-time chat application backend with WebSocket support, JWT authentication, and PostgreSQL database.

## Features

✅ User authentication (register/login with JWT)
✅ Real-time messaging via WebSockets
✅ Direct messages and group chats
✅ Message history and pagination
✅ Typing indicators
✅ Online/offline status
✅ Message status (sent/delivered/read)
✅ Reply to messages
✅ Support for multiple message types (text, image, video, audio, file)

## Project Structure

```
chat-backend/
├── main.go              # Application entry point
├── config/
│   └── middleware.go    # CORS and Auth middleware
├── database/
│   └── database.go      # Database connection and migration
├── models/
│   ├── user.go          # User model
│   ├── conversation.go  # Conversation model
│   └── message.go       # Message model
├── routes/
│   ├── auth.go          # Authentication endpoints
│   ├── user.go          # User endpoints
│   ├── conversation.go  # Conversation endpoints
│   └── websocket.go     # WebSocket implementation
├── .env                 # Environment variables
├── go.mod               # Go dependencies
└── README.md
```

## Prerequisites

- Go 1.21 or higher
- PostgreSQL 14 or higher
- Git

## Installation

### 1. Install Go

Download from [golang.org](https://golang.org/dl/)

### 2. Install PostgreSQL

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql
```

**macOS:**
```bash
brew install postgresql@15
brew services start postgresql@15
```

**Windows:**
Download from [postgresql.org](https://www.postgresql.org/download/windows/)

**Or use Docker (easiest):**
```bash
# Start PostgreSQL in Docker
docker-compose up -d postgres

# Check if it's running
docker ps
```

### 3. Setup Project

```bash
# Login to PostgreSQL
sudo -u postgres psql

# Create database and user
CREATE DATABASE chatapp;
CREATE USER chatuser WITH PASSWORD 'yourpassword';
GRANT ALL PRIVILEGES ON DATABASE chatapp TO chatuser;
\q
```

### 3. Setup Project

```bash
# Create project directory
mkdir chat-backend
cd chat-backend

# Initialize Go module
go mod init chat-backend

# Create project structure
mkdir -p config database models routes scripts migrations

# Copy all the code files to their respective directories
# (Use the artifacts provided)

# Install dependencies
go mod tidy
```

### 4. Configure Environment

Create `.env` file in project root:

```env
PORT=8080

DB_HOST=localhost
DB_USER=chatuser
DB_PASSWORD=yourpassword
DB_NAME=chatapp
DB_PORT=5432

JWT_SECRET=change-this-to-a-long-random-string-in-production
```

### 6. Install Migration Tool

```bash
# Install golang-migrate
go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@latest

# Or use the Makefile
make install-migrate
```

### 7. Run Migrations

```bash
# Create database
make db-create

# Run migrations
make migrate-up

# Optional: Seed with sample data
make db-seed
```

### 8. Run the Application

```bash
# Using go run
go run main.go

# Or using Makefile
make run

# Or build and run
make build
./bin/chat-server
```

The server will start on `http://localhost:8080`

## API Endpoints

### Authentication

**Register**
```http
POST /api/v1/auth/register
Content-Type: application/json

{
  "username": "john_doe",
  "email": "john@example.com",
  "password": "password123",
  "phone": "+1234567890"
}
```

**Login**
```http
POST /api/v1/auth/login
Content-Type: application/json

{
  "email": "john@example.com",
  "password": "password123"
}
```

**Logout**
```http
POST /api/v1/auth/logout
Authorization: Bearer <your_jwt_token>
```

### Users (Protected - requires JWT token)

**Get Current User**
```http
GET /api/v1/users/me
Authorization: Bearer <your_jwt_token>
```

**Get All Users**
```http
GET /api/v1/users
Authorization: Bearer <your_jwt_token>
```

### Conversations (Protected)

**Create Conversation**
```http
POST /api/v1/conversations
Authorization: Bearer <your_jwt_token>
Content-Type: application/json

# Direct message
{
  "type": "direct",
  "participant_id": 2
}

# Group chat
{
  "type": "group",
  "name": "My Group",
  "participant_ids": [2, 3, 4]
}
```

**Get Conversations**
```http
GET /api/v1/conversations
Authorization: Bearer <your_jwt_token>
```

**Get Messages**
```http
GET /api/v1/conversations/:id/messages
Authorization: Bearer <your_jwt_token>
```

### WebSocket

**Connect to WebSocket**
```
ws://localhost:8080/api/v1/ws
Authorization: Bearer <your_jwt_token> (in query or header)
```

**Send Message**
```json
{
  "type": "message",
  "conversation_id": 1,
  "content": "Hello, World!",
  "message_type": "text"
}
```

**Typing Indicator**
```json
{
  "type": "typing",
  "conversation_id": 1
}
```

## Testing with cURL

### 1. Register a user
```bash
curl -X POST http://localhost:8080/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"alice","email":"alice@example.com","password":"password123"}'
```

### 2. Login
```bash
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"alice@example.com","password":"password123"}'
```

Save the token from response!

### 3. Get users
```bash
curl http://localhost:8080/api/v1/users \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

### 4. Create conversation
```bash
curl -X POST http://localhost:8080/api/v1/conversations \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{"type":"direct","participant_id":2}'
```

## WebSocket Testing

Use a WebSocket client like [Postman](https://www.postman.com/) or [websocat](https://github.com/vi/websocat):

```bash
# Install websocat
cargo install websocat

# Connect to WebSocket
websocat "ws://localhost:8080/api/v1/ws" \
  --header "Authorization: Bearer YOUR_TOKEN_HERE"

# Send message
{"type":"message","conversation_id":1,"content":"Hello!"}
```

## Database Migrations

This project uses `golang-migrate` for database migrations.

### Migration Commands

```bash
# Install migrate tool
make install-migrate

# Create a new migration
make create-migration name=add_user_status

# Run all pending migrations
make migrate-up

# Rollback last migration
make migrate-down

# Rollback all migrations
make migrate-down-all

# Check current migration version
make migrate-version

# Go to specific version
make migrate-goto version=1

# Force set version (use with caution)
make migrate-force version=1

# Reset database (drop, create, migrate)
make db-reset
```

### Migration Files

Migrations are stored in `migrations/` directory:
- `000001_init_schema.up.sql` - Creates tables
- `000001_init_schema.down.sql` - Drops tables

When you create a new migration with `make create-migration name=your_name`, it creates two files:
- `XXXXXX_your_name.up.sql` - Forward migration
- `XXXXXX_your_name.down.sql` - Rollback migration

### Why Use Migrations?

✅ **Version Control**: Track database schema changes in Git
✅ **Reproducibility**: Other developers can replicate your database
✅ **Rollback**: Undo changes if something goes wrong
✅ **Team Collaboration**: Everyone stays in sync
✅ **Production Safety**: Apply changes systematically

## Database Schema

### Users Table
- id (primary key)
- username (unique)
- email (unique)
- password (hashed)
- phone
- avatar
- status (online/offline)
- last_seen
- created_at, updated_at

### Conversations Table
- id (primary key)
- type (direct/group)
- name
- avatar
- created_by (user_id)
- created_at, updated_at

### Messages Table
- id (primary key)
- conversation_id (foreign key)
- sender_id (foreign key)
- content
- type (text/image/video/audio/file)
- status (sent/delivered/read)
- media_url
- reply_to_id (self-referencing foreign key)
- created_at, updated_at, deleted_at

### Conversation Participants (join table)
- conversation_id
- user_id

## Next Steps for Learning

### For Go:
1. Learn Go basics: [tour.golang.org](https://tour.golang.org)
2. Understand goroutines and channels (crucial for WebSockets)
3. Study GORM documentation: [gorm.io](https://gorm.io)
4. Learn Gin framework: [gin-gonic.com](https://gin-gonic.com)

### Features to Add:
- [ ] File upload for images/videos
- [ ] Message encryption
- [ ] Push notifications (FCM)
- [ ] Message search
- [ ] User blocking
- [ ] Group admin features
- [ ] Voice/video calling (WebRTC)
- [ ] Message reactions
- [ ] Read receipts
- [ ] Last seen privacy settings

### Production Improvements:
- [ ] Add rate limiting
- [ ] Implement proper logging (logrus/zap)
- [ ] Add request validation
- [ ] Implement pagination for messages
- [ ] Add Redis for caching and session management
- [ ] Set up CI/CD pipeline
- [ ] Add unit and integration tests
- [ ] Implement database migrations (golang-migrate)
- [ ] Add API documentation (Swagger)
- [ ] Set up monitoring (Prometheus/Grafana)

## Troubleshooting

**Database connection error:**
- Check if PostgreSQL is running: `sudo systemctl status postgresql`
- Verify credentials in `.env` file
- Make sure database exists: `psql -U postgres -l`

**Port already in use:**
- Change PORT in `.env` file
- Or kill process: `lsof -ti:8080 | xargs kill`

**WebSocket connection fails:**
- Check if JWT token is valid
- Verify Authorization header format: `Bearer <token>`
- Check browser console for errors

## Resources

- [Go Documentation](https://golang.org/doc/)
- [Gin Framework](https://gin-gonic.com/docs/)
- [GORM](https://gorm.io/docs/)
- [Gorilla WebSocket](https://github.com/gorilla/websocket)
- [JWT](https://jwt.io/)

## License

MIT

---

**Ready to build your Flutter frontend?** Let me know when you want to start on that!
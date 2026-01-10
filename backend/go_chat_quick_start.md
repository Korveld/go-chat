# Quick Start Guide - Chat Backend

Get up and running in 5 minutes!

## Prerequisites
- Go 1.21+
- Docker (easiest option)
- OR PostgreSQL installed locally

## Option 1: Quick Start with Docker (Recommended)

```bash
# 1. Clone/setup project
mkdir chat-backend && cd chat-backend
git init
# Copy all code files from artifacts

# 2. Initialize Go module
go mod init chat-backend
go mod tidy

# 3. Create .env file
cat > .env << EOF
PORT=8080
DB_HOST=localhost
DB_USER=postgres
DB_PASSWORD=postgres
DB_NAME=chatapp
DB_PORT=5432
JWT_SECRET=$(openssl rand -base64 32)
EOF

# 4. Start PostgreSQL in Docker
docker-compose up -d

# 5. Install migration tool
make install-migrate

# 6. Run migrations
make migrate-up

# 7. Seed database with sample data
make db-seed

# 8. Start server
make run
```

✅ Server running at http://localhost:8080
✅ Sample users created (password: `password123`):
   - alice@example.com
   - bob@example.com
   - charlie@example.com
   - diana@example.com

## Option 2: Without Docker

```bash
# 1-3. Same as above

# 4. Create database
make db-create
# OR manually: createdb chatapp

# 5-8. Same as above
```

## Test It!

### 1. Login
```bash
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"alice@example.com","password":"password123"}'
```

Copy the `token` from response!

### 2. Get conversations
```bash
curl http://localhost:8080/api/v1/conversations \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

### 3. Get messages
```bash
curl http://localhost:8080/api/v1/conversations/1/messages \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

## Common Issues

**Port 5432 already in use:**
```bash
# Change DB_PORT in .env to 5433
DB_PORT=5433

# Update docker-compose.yml ports to "5433:5432"
```

**Migration errors:**
```bash
# Reset database
make db-reset
```

**Can't connect to database:**
```bash
# Check if PostgreSQL is running
docker ps
# OR
sudo systemctl status postgresql
```

## Next Steps

1. Read the full [README.md](README.md)
2. Explore the API with Postman
3. Test WebSocket connections
4. Start building your Flutter frontend!

## Useful Commands

```bash
make help              # Show all commands
make run               # Start server
make test              # Run tests
make migrate-version   # Check migration status
make db-seed           # Add sample data
```

## Project Structure

```
chat-backend/
├── main.go                    # Entry point
├── .env                       # Configuration
├── Makefile                   # Commands
├── docker-compose.yml         # Docker setup
├── config/
│   └── middleware.go          # Auth & CORS
├── database/
│   └── database.go            # DB connection
├── models/
│   └── *.go                   # Data models
├── routes/
│   ├── auth.go               # Login/register
│   ├── user.go               # User endpoints
│   ├── conversation.go       # Chat endpoints
│   └── websocket.go          # Real-time
├── migrations/
│   ├── 000001_*.up.sql       # Schema up
│   └── 000001_*.down.sql     # Schema down
└── scripts/
    └── seed.go               # Sample data
```

Happy coding! 🚀
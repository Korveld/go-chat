# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A real-time chat application with a Go backend and Flutter frontend. Features include JWT authentication, WebSocket-based messaging, direct messages, and group chats.

## Build and Run Commands

### Backend (Go + Gin + PostgreSQL)

```bash
cd backend

# Install dependencies
go mod download && go mod tidy

# Run the server (requires .env file - copy from .env.example)
make run              # or: go run main.go

# Build binary
make build            # outputs to bin/chat-server

# Run with hot reload (installs air automatically)
make dev

# Run tests
make test             # or: go test -v ./...
```

### Database Migrations

```bash
cd backend

# Install golang-migrate CLI
make install-migrate

# Create database
make db-create

# Run migrations
make migrate-up

# Rollback last migration
make migrate-down

# Create new migration
make create-migration name=your_migration_name

# Seed with sample data
make db-seed

# Reset database (drop, create, migrate)
make db-reset
```

### Frontend (Flutter)

```bash
cd frontend/go_chat

# Get dependencies
flutter pub get

# Copy environment file and configure backend URL
cp .env.example .env
# Edit .env if needed (defaults to localhost:8080)

# Run code generation (for freezed/json_serializable)
dart run build_runner build --delete-conflicting-outputs

# Run app
flutter run

# Run tests
flutter test
```

## Architecture

### Backend Structure

- **main.go**: Application entry point - sets up Gin router, middleware, and routes
- **config/middleware.go**: CORS and JWT auth middleware
- **database/database.go**: PostgreSQL connection via GORM with auto-migration
- **database/cleanup.go**: Background task for expired token cleanup
- **models/user.go**: All domain models (User, Conversation, Message, TokenBlacklist) in single file
- **routes/**: HTTP handlers organized by domain (auth, user, conversation, websocket)

### WebSocket Implementation

The WebSocket system in `routes/websocket.go` uses a Hub pattern:
- **Hub**: Central manager that tracks all connected clients via `userClients` map (userID -> Client)
- **Client**: Represents a WebSocket connection with send channel and associated userID
- **Message routing**: Messages are broadcast only to conversation participants, not globally

WebSocket message types: `message` (new chat message), `typing` (typing indicator)

### Frontend Structure

- **lib/main.dart**: App entry point with Riverpod provider scope
- **lib/services/**: API client (`api_service.dart`) and auth state management (`auth_service.dart`)
- **lib/screens/**: UI screens organized by feature (auth, home)
- **lib/models/**: Data models (User, Conversation, Message)
- **lib/core/theme/**: App theming (dark theme default)

State management uses Riverpod. API base URL is configured via `.env` file (see `lib/core/config/env_config.dart`).

## API Routes

All routes prefixed with `/api/v1`:
- Public: `POST /auth/register`, `POST /auth/login`
- Protected (require JWT): `/auth/logout`, `/users/*`, `/conversations/*`, `/ws`

## Environment Configuration

Backend requires `.env` file (see `.env.example`):
- `PORT`: Server port (default 8080)
- `DB_HOST`, `DB_USER`, `DB_PASSWORD`, `DB_NAME`, `DB_PORT`: PostgreSQL connection
- `JWT_SECRET`: Secret for JWT token signing

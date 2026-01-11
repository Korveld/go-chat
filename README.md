# Go Chat

A real-time chat application with a Go backend and Flutter frontend.

![Go](https://img.shields.io/badge/Go-00ADD8?style=flat&logo=go&logoColor=white)
![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat&logo=flutter&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=flat&logo=postgresql&logoColor=white)
![WebSocket](https://img.shields.io/badge/WebSocket-010101?style=flat&logo=socketdotio&logoColor=white)

## Features

- JWT authentication (register, login, logout)
- Real-time messaging via WebSocket
- Direct messages between users
- Group chat conversations
- Typing indicators
- User online/offline status
- Dark theme UI

## Tech Stack

**Backend:**
- Go with Gin framework
- PostgreSQL database
- GORM ORM
- JWT authentication
- WebSocket (gorilla/websocket)

**Frontend:**
- Flutter (cross-platform)
- Riverpod for state management
- Freezed for code generation

## Getting Started

### Prerequisites

- Go 1.21+
- PostgreSQL
- Flutter 3.x
- Make (optional, for using Makefile commands)

### Backend Setup

```bash
cd backend

# Install dependencies
go mod download && go mod tidy

# Copy environment file and configure
cp .env.example .env
# Edit .env with your database credentials

# Create database and run migrations
make db-create
make migrate-up

# (Optional) Seed with sample data
make db-seed

# Run the server
make run
```

The server will start at `http://localhost:8080`.

### Frontend Setup

```bash
cd frontend/go_chat

# Get dependencies
flutter pub get

# Run code generation
dart run build_runner build --delete-conflicting-outputs

# Run the app
flutter run
```

## Project Structure

```
go-chat/
├── backend/
│   ├── config/         # Middleware (CORS, JWT auth)
│   ├── database/       # Database connection and migrations
│   ├── models/         # Domain models (User, Conversation, Message)
│   ├── routes/         # HTTP handlers and WebSocket
│   └── main.go         # Application entry point
│
└── frontend/go_chat/
    ├── lib/
    │   ├── core/       # Theme and app configuration
    │   ├── models/     # Data models
    │   ├── screens/    # UI screens
    │   └── services/   # API and auth services
    └── pubspec.yaml
```

## API Endpoints

All routes are prefixed with `/api/v1`.

### Public Routes

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/auth/register` | Register a new user |
| POST | `/auth/login` | Login and get JWT token |

### Protected Routes (require JWT)

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/auth/logout` | Logout and invalidate token |
| GET | `/users` | List all users |
| GET | `/users/:id` | Get user by ID |
| GET | `/conversations` | List user's conversations |
| POST | `/conversations` | Create a new conversation |
| GET | `/conversations/:id/messages` | Get messages in conversation |
| WS | `/ws` | WebSocket connection |

## Environment Variables

Create a `.env` file in the `backend/` directory:

```env
PORT=8080
DB_HOST=localhost
DB_USER=postgres
DB_PASSWORD=your_password
DB_NAME=go_chat
DB_PORT=5432
JWT_SECRET=your_secret_key
```

## Database Commands

```bash
cd backend

make db-create           # Create database
make db-reset            # Drop, create, and migrate
make migrate-up          # Run all migrations
make migrate-down        # Rollback last migration
make create-migration name=migration_name  # Create new migration
```

## Development

### Backend with Hot Reload

```bash
cd backend
make dev  # Uses Air for hot reload
```

### Running Tests

```bash
# Backend
cd backend && make test

# Frontend
cd frontend/go_chat && flutter test
```

## License

MIT

# Chat App - Flutter Frontend

A beautiful cross-platform chat application built with Flutter. Features a Discord-like dark theme and works on macOS, Windows, and Linux desktop.

## Features

✅ Modern Discord-like dark UI
✅ User authentication (login/register)
✅ Real-time messaging (coming soon with WebSocket)
✅ Conversation list with last messages
✅ Direct messages
✅ Group chats (coming soon)
✅ Desktop support (macOS, Windows, Linux)

## Prerequisites

- Flutter SDK 3.0+
- Dart 3.0+
- Running backend server (Go chat backend)

## Project Structure

```
lib/
├── main.dart                          # App entry point
├── core/
│   └── theme/
│       └── app_theme.dart             # Dark theme (Discord-like)
├── models/
│   ├── user.dart                      # User model
│   ├── conversation.dart              # Conversation model
│   └── message.dart                   # Message model
├── services/
│   ├── api_service.dart               # HTTP API client
│   └── auth_service.dart              # Auth state management
└── screens/
    ├── auth/
    │   ├── login_screen.dart          # Login page
    │   └── register_screen.dart       # Register page
    └── home/
        ├── home_screen.dart           # Main layout
        └── widgets/
            ├── conversations_sidebar.dart  # Left sidebar
            ├── chat_area.dart             # Right chat area
            ├── new_chat_dialog.dart       # New chat dialog
            └── widgets/
                └── message_bubble.dart    # Message UI
```

## Installation

### 1. Install Flutter

Follow the official guide: [flutter.dev/docs/get-started/install](https://flutter.dev/docs/get-started/install)

**macOS:**
```bash
brew install flutter
```

**Check installation:**
```bash
flutter doctor
```

### 2. Enable Desktop Support

```bash
# macOS
flutter config --enable-macos-desktop

# Windows
flutter config --enable-windows-desktop

# Linux
flutter config --enable-linux-desktop
```

### 3. Setup Project

```bash
# Create Flutter project
flutter create chat_app
cd chat_app

# Copy all the code files from artifacts

# Get dependencies
flutter pub get
```

### 4. Configure API Endpoint

Edit `lib/services/api_service.dart`:

```dart
static const String baseUrl = 'http://localhost:8080/api/v1';
```

Change to your backend URL if different.

### 5. Run the App

**macOS:**
```bash
flutter run -d macos
```

**Windows:**
```bash
flutter run -d windows
```

**Linux:**
```bash
flutter run -d linux
```

**Or select device in VS Code/Android Studio**

## Usage

### Login
Use the demo credentials (if you seeded the database):
- Email: `alice@example.com`
- Password: `password123`

Or register a new account.

### Start a Chat
1. Click the `+` icon in the sidebar
2. Select a user from the list
3. Start messaging!

## Key Dependencies

```yaml
# State Management
flutter_riverpod: ^2.4.9

# HTTP & WebSocket
http: ^1.1.2
web_socket_channel: ^2.4.0

# Storage
shared_preferences: ^2.2.2
flutter_secure_storage: ^9.0.0

# UI
google_fonts: ^6.1.0
intl: ^0.19.0
```

## Color Scheme (Discord-like)

```dart
Primary: #5865F2 (Blurple)
Background: #36393F (Dark Gray)
Surface: #2F3136 (Slightly Lighter)
Sidebar: #202225 (Darkest)
Text Primary: #DCDDDE
Text Secondary: #96989D
Text Muted: #72767D
```

## State Management

Uses **Riverpod** for clean, scalable state management:

- `authProvider` - Current user authentication state
- `conversationsProvider` - List of conversations
- `messagesProvider` - Messages for selected conversation
- `selectedConversationProvider` - Currently open conversation

## API Integration

### Endpoints Used

```
POST /api/v1/auth/login
POST /api/v1/auth/register
POST /api/v1/auth/logout
GET  /api/v1/users/me
GET  /api/v1/users
GET  /api/v1/conversations
POST /api/v1/conversations
GET  /api/v1/conversations/:id/messages
```

### Authentication

JWT tokens are stored securely using `flutter_secure_storage` and automatically included in API requests.

## Coming Soon

- [✅] WebSocket real-time messaging
- [ ] Message status indicators (sent/delivered/read)
- [ ] Typing indicators
- [ ] File/image attachments
- [ ] Group chat creation
- [ ] User profile editing
- [ ] Push notifications
- [ ] Search messages
- [ ] Dark/Light theme toggle
- [ ] Message reactions
- [ ] Voice messages

## Development Tips

### Hot Reload
Press `r` in terminal or save files to hot reload changes instantly.

### Debug
```bash
flutter run --debug
```

### Release Build
```bash
# macOS
flutter build macos --release

# Windows
flutter build windows --release

# Linux
flutter build linux --release
```

### Common Issues

**"flutter_secure_storage" platform error:**
- macOS: Requires keychain access
- Windows: Should work out of the box
- Linux: Requires `libsecret-1-dev`
  ```bash
  sudo apt-get install libsecret-1-dev
  ```

**API connection error:**
- Make sure backend is running on `localhost:8080`
- Check CORS settings in backend
- Verify network permissions

**Desktop build fails:**
- Ensure desktop support is enabled: `flutter config --enable-<platform>-desktop`
- Run `flutter doctor` to check setup

## Building for Production

### macOS App
```bash
flutter build macos --release
# Output: build/macos/Build/Products/Release/chat_app.app
```

### Windows App
```bash
flutter build windows --release
# Output: build\windows\runner\Release\
```

### Linux App
```bash
flutter build linux --release
# Output: build/linux/x64/release/bundle/
```

## VS Code Setup

Install extensions:
- Flutter
- Dart

Add to `.vscode/launch.json`:
```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Flutter (Desktop)",
      "request": "launch",
      "type": "dart"
    }
  ]
}
```

## Testing

```bash
# Run tests
flutter test

# Run with coverage
flutter test --coverage
```

## Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Riverpod Documentation](https://riverpod.dev/)
- [Material Design 3](https://m3.material.io/)
- [Flutter Desktop](https://docs.flutter.dev/desktop)

## License

MIT

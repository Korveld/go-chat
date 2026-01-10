// lib/models/user.dart
class User {
  final int id;
  final String username;
  final String email;
  final String? phone;
  final String? avatar;
  final String status;
  final DateTime lastSeen;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.phone,
    this.avatar,
    required this.status,
    required this.lastSeen,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      phone: json['phone'],
      avatar: json['avatar'],
      status: json['status'] ?? 'offline',
      lastSeen: DateTime.parse(json['last_seen']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'phone': phone,
      'avatar': avatar,
      'status': status,
      'last_seen': lastSeen.toIso8601String(),
    };
  }
}

// lib/models/conversation.dart
class Conversation {
  final int id;
  final String type;
  final String? name;
  final String? avatar;
  final List<User> participants;
  final Message? lastMessage;
  final DateTime createdAt;
  final DateTime updatedAt;

  Conversation({
    required this.id,
    required this.type,
    this.name,
    this.avatar,
    required this.participants,
    this.lastMessage,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'],
      type: json['type'],
      name: json['name'],
      avatar: json['avatar'],
      participants: (json['participants'] as List?)
          ?.map((p) => User.fromJson(p))
          .toList() ?? [],
      lastMessage: json['messages'] != null && (json['messages'] as List).isNotEmpty
          ? Message.fromJson(json['messages'][0])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  String getDisplayName(int currentUserId) {
    if (type == 'group') {
      return name ?? 'Group Chat';
    }
    // For direct messages, show the other user's name
    final otherUser = participants.firstWhere(
          (u) => u.id != currentUserId,
      orElse: () => participants.first,
    );
    return otherUser.username;
  }

  String? getDisplayAvatar(int currentUserId) {
    if (type == 'group') {
      return avatar;
    }
    final otherUser = participants.firstWhere(
          (u) => u.id != currentUserId,
      orElse: () => participants.first,
    );
    return otherUser.avatar;
  }
}

// lib/models/message.dart
class Message {
  final int id;
  final int conversationId;
  final int senderId;
  final User? sender;
  final String content;
  final String type;
  final String status;
  final String? mediaUrl;
  final int? replyToId;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.sender,
    required this.content,
    required this.type,
    required this.status,
    this.mediaUrl,
    this.replyToId,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      conversationId: json['conversation_id'],
      senderId: json['sender_id'],
      sender: json['sender'] != null ? User.fromJson(json['sender']) : null,
      content: json['content'] ?? '',
      type: json['type'] ?? 'text',
      status: json['status'] ?? 'sent',
      mediaUrl: json['media_url'],
      replyToId: json['reply_to_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'conversation_id': conversationId,
      'content': content,
      'type': type,
    };
  }
}
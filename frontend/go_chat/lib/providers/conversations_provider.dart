import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/websocket_service.dart';
import 'websocket_provider.dart';

class ConversationsNotifier extends StateNotifier<AsyncValue<List<Conversation>>> {
  final ApiService _apiService;
  final WebSocketService _wsService;
  StreamSubscription? _wsSubscription;

  ConversationsNotifier(this._apiService, this._wsService)
      : super(const AsyncValue.loading()) {
    _subscribeToWebSocket();
    loadConversations();
  }

  void _subscribeToWebSocket() {
    _wsSubscription = _wsService.messageStream.listen(_handleIncomingMessage);
  }

  void _handleIncomingMessage(Map<String, dynamic> data) {
    final wsMessage = WsIncomingMessage.fromJson(data);

    switch (wsMessage) {
      case WsNewMessage(:final message):
        _updateConversationLastMessage(message);
      case WsTypingIndicator():
        break;
      case WsStatusChange(:final userId, :final status):
        _updateUserStatus(userId, status);
      case WsUnknown():
        break;
    }
  }

  void _updateConversationLastMessage(Message message) {
    state.whenData((conversations) {
      final updatedList = conversations.map((c) {
        if (c.id == message.conversationId) {
          return c.copyWith(
            lastMessage: message,
            updatedAt: DateTime.now(),
          );
        }
        return c;
      }).toList();

      // Sort by last message time (newest first)
      updatedList.sort((a, b) {
        final aTime = a.lastMessage?.createdAt ?? a.updatedAt;
        final bTime = b.lastMessage?.createdAt ?? b.updatedAt;
        return bTime.compareTo(aTime);
      });

      state = AsyncValue.data(updatedList);
    });
  }

  void _updateUserStatus(int userId, String status) {
    state.whenData((conversations) {
      final updatedList = conversations.map((c) {
        final updatedParticipants = c.participants.map((user) {
          if (user.id == userId) {
            return user.copyWith(status: status);
          }
          return user;
        }).toList();

        return c.copyWith(participants: updatedParticipants);
      }).toList();

      state = AsyncValue.data(updatedList);
    });
  }

  Future<void> loadConversations() async {
    state = const AsyncValue.loading();
    try {
      final conversations = await _apiService.getConversations();
      state = AsyncValue.data(conversations);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void addConversation(Conversation conversation) {
    state.whenData((conversations) {
      // Check if already exists
      if (conversations.any((c) => c.id == conversation.id)) return;

      state = AsyncValue.data([conversation, ...conversations]);
    });
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    super.dispose();
  }
}

final conversationsNotifierProvider =
    StateNotifierProvider<ConversationsNotifier, AsyncValue<List<Conversation>>>((ref) {
  final apiService = ref.read(apiServiceProvider);
  final wsService = ref.read(webSocketServiceProvider);
  return ConversationsNotifier(apiService, wsService);
});

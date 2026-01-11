import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/websocket_service.dart';
import 'websocket_provider.dart';

class MessagesState {
  final Map<int, List<Message>> messagesByConversation;
  final Map<int, bool> loadingStates;
  final Map<int, String?> errors;

  const MessagesState({
    this.messagesByConversation = const {},
    this.loadingStates = const {},
    this.errors = const {},
  });

  MessagesState copyWith({
    Map<int, List<Message>>? messagesByConversation,
    Map<int, bool>? loadingStates,
    Map<int, String?>? errors,
  }) {
    return MessagesState(
      messagesByConversation: messagesByConversation ?? this.messagesByConversation,
      loadingStates: loadingStates ?? this.loadingStates,
      errors: errors ?? this.errors,
    );
  }
}

class MessagesNotifier extends StateNotifier<MessagesState> {
  final ApiService _apiService;
  final WebSocketService _wsService;
  StreamSubscription? _wsSubscription;

  MessagesNotifier(this._apiService, this._wsService) : super(const MessagesState()) {
    _subscribeToWebSocket();
  }

  void _subscribeToWebSocket() {
    _wsSubscription = _wsService.messageStream.listen(_handleIncomingMessage);
  }

  void _handleIncomingMessage(Map<String, dynamic> data) {
    final wsMessage = WsIncomingMessage.fromJson(data);

    switch (wsMessage) {
      case WsNewMessage(:final message):
        _addMessage(message);
      case WsTypingIndicator():
        // Could handle typing indicator here if needed
        break;
      case WsStatusChange():
        // Status changes are handled by ConversationsNotifier
        break;
      case WsUnknown():
        break;
    }
  }

  Future<void> loadMessages(int conversationId) async {
    // Skip if already loading
    if (state.loadingStates[conversationId] == true) return;

    // Set loading state
    state = state.copyWith(
      loadingStates: {...state.loadingStates, conversationId: true},
      errors: {...state.errors, conversationId: null},
    );

    try {
      final messages = await _apiService.getMessages(conversationId);
      state = state.copyWith(
        messagesByConversation: {...state.messagesByConversation, conversationId: messages},
        loadingStates: {...state.loadingStates, conversationId: false},
      );
    } catch (e) {
      state = state.copyWith(
        loadingStates: {...state.loadingStates, conversationId: false},
        errors: {...state.errors, conversationId: e.toString()},
      );
    }
  }

  void _addMessage(Message message) {
    final conversationId = message.conversationId;
    final currentMessages = state.messagesByConversation[conversationId] ?? [];

    // Avoid duplicates
    if (currentMessages.any((m) => m.id == message.id)) return;

    final updatedMessages = [...currentMessages, message];

    state = state.copyWith(
      messagesByConversation: {...state.messagesByConversation, conversationId: updatedMessages},
    );
  }

  void sendMessage(int conversationId, String content) {
    _wsService.sendMessage(
      conversationId: conversationId,
      content: content,
    );
  }

  void sendTypingIndicator(int conversationId) {
    _wsService.sendTypingIndicator(conversationId);
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    super.dispose();
  }
}

final messagesNotifierProvider = StateNotifierProvider<MessagesNotifier, MessagesState>((ref) {
  final apiService = ref.read(apiServiceProvider);
  final wsService = ref.read(webSocketServiceProvider);
  return MessagesNotifier(apiService, wsService);
});

final conversationMessagesProvider = Provider.family<List<Message>, int>((ref, conversationId) {
  final state = ref.watch(messagesNotifierProvider);
  return state.messagesByConversation[conversationId] ?? [];
});

final conversationLoadingProvider = Provider.family<bool, int>((ref, conversationId) {
  final state = ref.watch(messagesNotifierProvider);
  return state.loadingStates[conversationId] ?? false;
});

final conversationErrorProvider = Provider.family<String?, int>((ref, conversationId) {
  final state = ref.watch(messagesNotifierProvider);
  return state.errors[conversationId];
});

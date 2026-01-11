// lib/providers/unread_provider.dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../screens/home/home_screen.dart';
import 'websocket_provider.dart';

class UnreadNotifier extends StateNotifier<Map<int, int>> {
  UnreadNotifier() : super({});

  void incrementUnread(int conversationId) {
    final currentCount = state[conversationId] ?? 0;
    state = {...state, conversationId: currentCount + 1};
  }

  void clearUnread(int conversationId) {
    if (state.containsKey(conversationId)) {
      state = {...state, conversationId: 0};
    }
  }

  int getUnreadCount(int conversationId) {
    return state[conversationId] ?? 0;
  }
}

final unreadNotifierProvider =
    StateNotifierProvider<UnreadNotifier, Map<int, int>>((ref) {
  return UnreadNotifier();
});

/// Provider that listens for new messages and updates unread counts
final unreadListenerProvider = Provider<void>((ref) {
  final wsService = ref.watch(webSocketServiceProvider);
  final authState = ref.watch(authNotifierProvider);
  final selectedConversation = ref.watch(selectedConversationProvider);

  final currentUserId = authState.value?.id;
  if (currentUserId == null) return;

  final subscription = wsService.messageStream.listen((data) {
    final wsMessage = WsIncomingMessage.fromJson(data);

    if (wsMessage case WsNewMessage(:final message)) {
      // Don't count own messages
      if (message.senderId == currentUserId) return;

      // Don't count if we're viewing that conversation
      if (message.conversationId == selectedConversation) return;

      // Increment unread count
      ref.read(unreadNotifierProvider.notifier).incrementUnread(message.conversationId);
    }
  });

  ref.onDispose(() {
    subscription.cancel();
  });
});

/// Provider to get unread count for a specific conversation
final unreadCountProvider = Provider.family<int, int>((ref, conversationId) {
  final unreadState = ref.watch(unreadNotifierProvider);
  return unreadState[conversationId] ?? 0;
});

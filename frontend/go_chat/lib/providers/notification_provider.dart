// lib/providers/notification_provider.dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../screens/home/home_screen.dart';
import 'websocket_provider.dart';
import 'conversations_provider.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = NotificationService();

  // Set up notification click handler
  service.onNotificationClick = (conversationId) {
    // Update selected conversation
    ref.read(selectedConversationProvider.notifier).state = conversationId;
  };

  return service;
});

final notificationListenerProvider = Provider<void>((ref) {
  final wsService = ref.watch(webSocketServiceProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  final authState = ref.watch(authNotifierProvider);
  final conversationsState = ref.read(conversationsNotifierProvider);

  final currentUserId = authState.value?.id;
  if (currentUserId == null) {
    print('Notification: No current user, skipping listener setup');
    return;
  }

  print('Notification: Setting up listener for user $currentUserId');

  final subscription = wsService.messageStream.listen((data) {
    print('Notification: Received WebSocket message: $data');

    final wsMessage = WsIncomingMessage.fromJson(data);

    if (wsMessage case WsNewMessage(:final message)) {
      print('Notification: New message from ${message.senderId}, current user: $currentUserId');

      // Don't notify for own messages
      if (message.senderId == currentUserId) {
        print('Notification: Skipping own message');
        return;
      }

      // Get sender name from conversation participants or message sender
      String senderName = 'New message';

      if (message.sender != null) {
        senderName = message.sender!.username;
      } else {
        // Try to find sender from conversations
        conversationsState.whenData((conversations) {
          for (final conv in conversations) {
            final sender = conv.participants.where((p) => p.id == message.senderId).firstOrNull;
            if (sender != null) {
              senderName = sender.username;
              break;
            }
          }
        });
      }

      print('Notification: Showing notification from $senderName: ${message.content}');

      notificationService.showMessageNotification(
        conversationId: message.conversationId,
        senderName: senderName,
        message: message.content,
      );
    }
  });

  ref.onDispose(() {
    print('Notification: Disposing listener');
    subscription.cancel();
  });
});

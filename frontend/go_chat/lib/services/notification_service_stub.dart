// lib/services/notification_service_stub.dart
// Stub implementation for web platform

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  void Function(int conversationId)? onNotificationClick;

  Future<void> init() async {
    // No-op on web
  }

  Future<bool> isWindowFocused() async {
    return true; // Always focused on web (no notifications)
  }

  Future<void> showMessageNotification({
    required int conversationId,
    required String senderName,
    required String message,
  }) async {
    // No-op on web
  }
}

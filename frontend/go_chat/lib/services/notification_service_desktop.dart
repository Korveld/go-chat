// lib/services/notification_service_desktop.dart
import 'dart:io' show Platform;
import 'package:local_notifier/local_notifier.dart';
import 'package:window_manager/window_manager.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _initialized = false;
  void Function(int conversationId)? onNotificationClick;

  static bool get isDesktop {
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  Future<void> init() async {
    print('NotificationService: init called, isDesktop=$isDesktop');

    if (!isDesktop) {
      print('NotificationService: Not desktop, skipping init');
      return;
    }
    if (_initialized) {
      print('NotificationService: Already initialized');
      return;
    }

    await windowManager.ensureInitialized();
    await localNotifier.setup(
      appName: 'Go Chat',
      shortcutPolicy: ShortcutPolicy.requireCreate,
    );

    _initialized = true;
    print('NotificationService: Initialization complete');
  }

  Future<bool> isWindowFocused() async {
    if (!isDesktop || !_initialized) return true;

    try {
      final isFocused = await windowManager.isFocused();
      final isVisible = await windowManager.isVisible();
      final isMinimized = await windowManager.isMinimized();

      // Show notification if window is minimized, not visible, or not focused
      return isFocused && isVisible && !isMinimized;
    } catch (e) {
      return true; // Assume focused if we can't determine
    }
  }

  Future<void> showMessageNotification({
    required int conversationId,
    required String senderName,
    required String message,
  }) async {
    print('NotificationService: showMessageNotification called');
    print('NotificationService: isDesktop=$isDesktop, _initialized=$_initialized');

    if (!isDesktop || !_initialized) {
      print('NotificationService: Not desktop or not initialized, skipping');
      return;
    }

    final isFocused = await isWindowFocused();
    print('NotificationService: isWindowFocused=$isFocused');

    // Don't show notification if window is focused
    if (isFocused) {
      print('NotificationService: Window is focused, skipping notification');
      return;
    }

    print('NotificationService: Creating notification from $senderName: $message');

    final notification = LocalNotification(
      identifier: 'message_$conversationId',
      title: senderName,
      body: message,
    );

    notification.onClick = () {
      _handleNotificationClick(conversationId);
    };

    notification.show();
    print('NotificationService: Notification shown');
  }

  Future<void> _handleNotificationClick(int conversationId) async {
    if (!isDesktop || !_initialized) return;

    // Bring window to front
    await windowManager.show();
    await windowManager.focus();

    // Notify the app to navigate to the conversation
    onNotificationClick?.call(conversationId);
  }
}

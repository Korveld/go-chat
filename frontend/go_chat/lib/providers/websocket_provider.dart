import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/auth_service.dart';
import '../services/websocket_service.dart';

final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  final service = WebSocketService();
  ref.onDispose(() => service.dispose());
  return service;
});

final webSocketConnectionProvider = Provider<void>((ref) {
  final authState = ref.watch(authNotifierProvider);
  final wsService = ref.read(webSocketServiceProvider);
  const storage = FlutterSecureStorage();

  authState.whenData((user) async {
    if (user != null) {
      final token = await storage.read(key: 'auth_token');
      if (token != null) {
        wsService.connect(token);
      }
    } else {
      wsService.disconnect();
    }
  });
});

final wsConnectionStateProvider = StreamProvider<bool>((ref) {
  final wsService = ref.watch(webSocketServiceProvider);
  return wsService.connectionState;
});

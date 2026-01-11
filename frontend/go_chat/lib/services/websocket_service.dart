import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';
import '../core/config/env_config.dart';

class WebSocketService {
  static String get _wsBaseUrl => EnvConfig.wsBaseUrl;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  Timer? _pingTimer;

  String? _token;
  bool _isConnected = false;
  bool _shouldReconnect = true;
  int _reconnectAttempts = 0;
  static const int _maxReconnectDelay = 30;

  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  final _connectionStateController = StreamController<bool>.broadcast();
  Stream<bool> get connectionState => _connectionStateController.stream;

  bool get isConnected => _isConnected;

  Future<void> connect(String token) async {
    if (_isConnected && _token == token) return;

    _token = token;
    _shouldReconnect = true;
    await _connect();
  }

  Future<void> _connect() async {
    if (_token == null) return;

    try {
      _cancelTimers();

      final uri = Uri.parse('$_wsBaseUrl?token=$_token');
      _channel = WebSocketChannel.connect(uri);

      await _channel!.ready;

      _isConnected = true;
      _reconnectAttempts = 0;
      _connectionStateController.add(true);

      _subscription = _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDone,
        cancelOnError: false,
      );

      _startPingTimer();
    } catch (e) {
      _isConnected = false;
      _connectionStateController.add(false);
      _scheduleReconnect();
    }
  }

  void _handleMessage(dynamic data) {
    try {
      final decoded = jsonDecode(data as String) as Map<String, dynamic>;
      _messageController.add(decoded);
    } catch (e) {
      // Ignore malformed messages
    }
  }

  void _handleError(dynamic error) {
    _isConnected = false;
    _connectionStateController.add(false);
    _scheduleReconnect();
  }

  void _handleDone() {
    _isConnected = false;
    _connectionStateController.add(false);
    if (_shouldReconnect) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (!_shouldReconnect || _reconnectTimer != null) return;

    final delay = _calculateReconnectDelay();
    _reconnectTimer = Timer(Duration(seconds: delay), () {
      _reconnectTimer = null;
      _reconnectAttempts++;
      _connect();
    });
  }

  int _calculateReconnectDelay() {
    final delay = 1 << _reconnectAttempts; // Exponential: 1, 2, 4, 8...
    return delay > _maxReconnectDelay ? _maxReconnectDelay : delay;
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_isConnected && _channel != null) {
        try {
          _channel!.sink.add(jsonEncode({'type': 'ping'}));
        } catch (e) {
          // Connection may have dropped
        }
      }
    });
  }

  void _cancelTimers() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  void disconnect() {
    _shouldReconnect = false;
    _cancelTimers();
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    _token = null;
    _reconnectAttempts = 0;
    _connectionStateController.add(false);
  }

  void sendMessage({
    required int conversationId,
    required String content,
    String messageType = 'text',
    int? replyToId,
  }) {
    if (!_isConnected || _channel == null) return;

    final message = {
      'type': 'message',
      'conversation_id': conversationId,
      'content': content,
      'message_type': messageType,
      if (replyToId != null) 'reply_to_id': replyToId,
    };

    _channel!.sink.add(jsonEncode(message));
  }

  void sendTypingIndicator(int conversationId) {
    if (!_isConnected || _channel == null) return;

    final message = {
      'type': 'typing',
      'conversation_id': conversationId,
    };

    _channel!.sink.add(jsonEncode(message));
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _connectionStateController.close();
  }
}

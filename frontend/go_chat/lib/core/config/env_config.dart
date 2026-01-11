import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://localhost:8080/api/v1';

  static String get wsBaseUrl =>
      dotenv.env['WS_BASE_URL'] ?? 'ws://localhost:8080/api/v1/ws';
}

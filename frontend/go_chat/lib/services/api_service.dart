// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8080/api/v1';
  String? _token;

  void setToken(String token) {
    _token = token;
  }

  void clearToken() {
    _token = null;
  }

  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // Auth
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)['error'] ?? 'Login failed');
    }
  }

  Future<Map<String, dynamic>> register(
      String username,
      String email,
      String password,
      String phone,
      ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
        'phone': phone,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)['error'] ?? 'Registration failed');
    }
  }

  Future<void> logout() async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/logout'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Logout failed');
    }
  }

  // Users
  Future<User> getCurrentUser() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/me'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return User.fromJson(data['user']);
    } else {
      throw Exception('Failed to get user');
    }
  }

  Future<List<User>> getUsers() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['users'] as List)
          .map((u) => User.fromJson(u))
          .toList();
    } else {
      throw Exception('Failed to get users');
    }
  }

  Future<List<User>> searchUsers(String query) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users?search=${Uri.encodeComponent(query)}'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['users'] as List)
          .map((u) => User.fromJson(u))
          .toList();
    } else {
      throw Exception('Failed to search users');
    }
  }

  // Conversations
  Future<List<Conversation>> getConversations() async {
    final response = await http.get(
      Uri.parse('$baseUrl/conversations'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['conversations'] as List)
          .map((c) => Conversation.fromJson(c))
          .toList();
    } else {
      throw Exception('Failed to get conversations');
    }
  }

  Future<Conversation> createConversation({
    required String type,
    String? name,
    int? participantId,
    List<int>? participantIds,
  }) async {
    final body = {
      'type': type,
      if (name != null) 'name': name,
      if (participantId != null) 'participant_id': participantId,
      if (participantIds != null) 'participant_ids': participantIds,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/conversations'),
      headers: _headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return Conversation.fromJson(data['conversation']);
    } else {
      throw Exception('Failed to create conversation');
    }
  }

  Future<List<Message>> getMessages(int conversationId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/conversations/$conversationId/messages'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['messages'] as List)
          .map((m) => Message.fromJson(m))
          .toList();
    } else {
      throw Exception('Failed to get messages');
    }
  }
}
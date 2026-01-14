// lib/services/auth_service.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import 'api_service.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

final authProvider = StreamProvider<User?>((ref) async* {
  final storage = const FlutterSecureStorage();
  final apiService = ref.read(apiServiceProvider);

  // Check if we have a stored token
  final token = await storage.read(key: 'auth_token');

  if (token != null) {
    apiService.setToken(token);
    try {
      final user = await apiService.getCurrentUser();
      yield user;
    } catch (e) {
      await storage.delete(key: 'auth_token');
      apiService.clearToken();
      yield null;
    }
  } else {
    yield null;
  }
});

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final ApiService _apiService;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthNotifier(this._apiService) : super(const AsyncValue.loading()) {
    _initAuth();
  }

  Future<void> _initAuth() async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token != null) {
        _apiService.setToken(token);
        final user = await _apiService.getCurrentUser();
        state = AsyncValue.data(user);
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e) {
      // Token is invalid or user doesn't exist - clear token and go to login
      await _storage.delete(key: 'auth_token');
      _apiService.clearToken();
      state = const AsyncValue.data(null);
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final response = await _apiService.login(email, password);
      final token = response['token'];
      final user = User.fromJson(response['user']);

      await _storage.write(key: 'auth_token', value: token);
      _apiService.setToken(token);

      state = AsyncValue.data(user);
    } catch (e, stack) {
      // Restore state to unauthenticated so UI doesn't get stuck
      state = const AsyncValue.data(null);
      rethrow;
    }
  }

  Future<void> register(String username, String email, String password, String phone) async {
    state = const AsyncValue.loading();
    try {
      final response = await _apiService.register(username, email, password, phone);
      final token = response['token'];
      final user = User.fromJson(response['user']);

      await _storage.write(key: 'auth_token', value: token);
      _apiService.setToken(token);

      state = AsyncValue.data(user);
    } catch (e, stack) {
      // Restore state to unauthenticated so UI doesn't get stuck
      state = const AsyncValue.data(null);
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _apiService.logout();
    } catch (e) {
      // Continue with logout even if API call fails
    } finally {
      await _storage.delete(key: 'auth_token');
      _apiService.clearToken();
      state = const AsyncValue.data(null);
    }
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  return AuthNotifier(ref.read(apiServiceProvider));
});
import 'package:dio/dio.dart';
import 'token_storage.dart';
import '../models/user.dart';
import 'api_service.dart';
import 'auth_state.dart';
import 'cache_manager.dart';

class AuthService {
  final _api = ApiService();

  Future<(User, String, String)> login(String email, String password) async {
    final response = await _api.dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });

    final accessToken = response.data['access_token'] as String;
    final refreshToken = response.data['refresh_token'] as String;

    // Save tokens
    await TokenStorage.saveTokens(accessToken, refreshToken);
    authNotifier.onLogin(); // Notify router — triggers synchronous redirect

    // Fetch current user
    final userResponse = await _api.dio.get(
      '/auth/me',
      options: Options(headers: {
        'Authorization': 'Bearer $accessToken',
      }),
    );

    final user = User.fromJson(userResponse.data as Map<String, dynamic>);
    return (user, accessToken, refreshToken);
  }

  Future<User> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    await _api.dio.post('/auth/register', data: {
      'email': email,
      'password': password,
      'full_name': fullName,
      if (phone != null) 'phone': phone,
    });

    final (user, _, _) = await login(email, password);
    return user;
  }

  Future<void> logout() async {
    try {
      await _api.dio.post('/auth/logout');
    } catch (_) {
      // Ignore errors on logout
    }
    await TokenStorage.clearTokens();
    await CacheManager.clearAll();
    authNotifier.onLogout(); // Notify router to redirect to /login
  }

  Future<User?> getCurrentUser() async {
    final token = await TokenStorage.getAccessToken();
    if (token == null) return null;
    try {
      final response = await _api.dio.get('/auth/me');
      return User.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}

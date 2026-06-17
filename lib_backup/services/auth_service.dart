import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'api_service.dart';
import 'auth_state.dart';

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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    authNotifier.onLogout(); // Notify router to redirect to /login
  }

  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) return null;
    try {
      final response = await _api.dio.get('/auth/me');
      return User.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}

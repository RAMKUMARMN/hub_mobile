import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import 'api_service.dart';
import 'auth_state.dart';

class AuthService {
  final _api = ApiService();

  Future<(User, String, String)> login(
    String email,
    String password,
  ) async {
    try {
      final response = await _api.dio.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      final accessToken = response.data['access_token'] as String?;

      final refreshToken = response.data['refresh_token'] as String?;

      if (accessToken == null || refreshToken == null) {
        throw Exception('Invalid authentication response.');
      }

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(
        'access_token',
        accessToken,
      );

      await prefs.setString(
        'refresh_token',
        refreshToken,
      );

      authNotifier.onLogin();

      final userResponse = await _api.dio.get(
        '/auth/me',
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
          },
        ),
      );

      final user = User.fromJson(
        userResponse.data as Map<String, dynamic>,
      );

      return (user, accessToken, refreshToken);
    } on DioException catch (e) {
      final message = e.response?.data is Map<String, dynamic>
          ? (e.response?.data['detail']?.toString() ?? e.message)
          : e.message;

      throw Exception(
        message ?? 'Unable to connect to the server.',
      );
    } catch (e) {
      debugPrint('Login error: $e');

      throw Exception(
        'Login failed. Please try again.',
      );
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    String? deviceToken, // 🚀 1. Add this parameter line
  }) async {
    try {
      await _api.dio.post(
        '/auth/register',
        data: {
          'email': email,
          'password': password,
          'full_name': fullName,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
          if (deviceToken != null && deviceToken.isNotEmpty)
            'device_token':
                deviceToken, // 🚀 2. Pass it to your FastAPI backend
        },
      );

      // 💡 Note: We removed the auto-login line here because the user
      // needs to type in their 6-digit OTP code first on the next screen!
    } on DioException catch (e) {
      final message = e.response?.data is Map<String, dynamic>
          ? (e.response?.data['detail']?.toString() ?? e.message)
          : e.message;

      throw Exception(
        message ?? 'Registration failed.',
      );
    } catch (e) {
      debugPrint('Registration error: $e');

      throw Exception(
        'Something went wrong during registration.',
      );
    }
  }

  Future<void> logout() async {
    try {
      await _api.dio.post('/auth/logout');
    } on DioException catch (e) {
      debugPrint('Logout API error: ${e.message}');
    } catch (e) {
      debugPrint('Logout error: $e');
    } finally {
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove('access_token');
      await prefs.remove('refresh_token');

      authNotifier.onLogout();
    }
  }

  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('access_token');

    if (token == null || token.isEmpty) {
      return null;
    }

    try {
      final response = await _api.dio.get('/auth/me');

      return User.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      debugPrint(
        'getCurrentUser Dio error: ${e.message}',
      );

      return null;
    } catch (e) {
      debugPrint(
        'getCurrentUser error: $e',
      );

      return null;
    }
  }
}

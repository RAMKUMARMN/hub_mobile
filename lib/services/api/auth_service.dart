// lib/services/api/auth_service.dart
import 'api_client.dart';

class AuthService {
  final ApiClient _client = ApiClient();

  /// Login with email and password
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.request(
      method: 'POST',
      endpoint: '/auth/login',
      requiresAuth: false,
      body: {'email': email, 'password': password},
    );
    
    if (response['success'] == true) {
      final data = response['data'];
      return {
        'success': true,
        'token': data['access_token'],
        'user_id': data['user']['id'],
        'name': data['user']['name'],
        'email': data['user']['email'],
      };
    }
    return response;
  }

  /// Register new user
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _client.request(
      method: 'POST',
      endpoint: '/auth/register',
      requiresAuth: false,
      body: {'name': name, 'email': email, 'password': password},
    );
    
    if (response['success'] == true) {
      final data = response['data'];
      return {
        'success': true,
        'token': data['access_token'],
        'user_id': data['user']['id'],
        'name': data['user']['name'],
        'email': data['user']['email'],
      };
    }
    return response;
  }

  /// Google login
  Future<Map<String, dynamic>> googleLogin({
    required String email,
    required String name,
    required String googleId,
    String? photoUrl,
  }) async {
    final response = await _client.request(
      method: 'POST',
      endpoint: '/auth/google-login',
      requiresAuth: false,
      body: {
        'email': email,
        'name': name,
        'google_id': googleId,
      },
    );
    
    if (response['success'] == true) {
      final data = response['data'];
      return {
        'success': true,
        'token': data['access_token'],
        'user_id': data['user']['id'],
        'name': data['user']['name'],
        'email': data['user']['email'],
      };
    }
    return response;
  }

  /// Get current user profile
  Future<Map<String, dynamic>> getProfile() async {
    return await _client.request(
      method: 'GET',
      endpoint: '/auth/me',
    );
  }

  /// Update user profile
  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? email,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (email != null) body['email'] = email;
    
    return await _client.request(
      method: 'PUT',
      endpoint: '/auth/profile',
      body: body,
    );
  }

  /// Change password
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    return await _client.request(
      method: 'POST',
      endpoint: '/auth/change-password',
      body: {
        'current_password': currentPassword,
        'new_password': newPassword,
      },
    );
  }

  /// Delete account
  Future<Map<String, dynamic>> deleteAccount() async {
    return await _client.request(
      method: 'DELETE',
      endpoint: '/auth/account',
    );
  }
}
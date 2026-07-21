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
      final tokenData = response['data'];
      final String token = tokenData['access_token'];
      final String refreshToken = tokenData['refresh_token'];
      
      // Fetch user profile info using the token we just received
      final profileResponse = await _client.request(
        method: 'GET',
        endpoint: '/auth/me',
        requiresAuth: true,
        customHeaders: {'Authorization': 'Bearer $token'},
      );
      
      if (profileResponse['success'] == true) {
        final userData = profileResponse['data'];
        return {
          'success': true,
          'token': token,
          'refresh_token': refreshToken,
          'user_id': userData['id'],
          'name': userData['full_name'],
          'email': userData['email'],
        };
      } else {
        return profileResponse;
      }
    }
    return response;
  }

  /// Register new user
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    return await _client.request(
      method: 'POST',
      endpoint: '/auth/register',
      requiresAuth: false,
      body: {'full_name': name, 'email': email, 'password': password},
    );
  }

  /// Verify OTP
  Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    return await _client.request(
      method: 'POST',
      endpoint: '/auth/verify-otp',
      requiresAuth: false,
      body: {'email': email, 'otp': otp},
    );
  }

  /// Resend OTP
  Future<Map<String, dynamic>> resendOtp({
    required String email,
  }) async {
    return await _client.request(
      method: 'POST',
      endpoint: '/auth/resend-otp',
      requiresAuth: false,
      body: {'email': email},
    );
  }

  /// Refresh JWT tokens
  Future<Map<String, dynamic>> refreshToken({
    required String refreshToken,
  }) async {
    return await _client.request(
      method: 'POST',
      endpoint: '/auth/refresh',
      requiresAuth: false,
      body: {'refresh_token': refreshToken},
    );
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
        'refresh_token': data['refresh_token'],
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

  /// Initiate forgot password
  Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    return await _client.request(
      method: 'POST',
      endpoint: '/auth/forgot-password',
      requiresAuth: false,
      body: {'email': email},
    );
  }

  /// Confirm reset password
  Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    return await _client.request(
      method: 'POST',
      endpoint: '/auth/reset-password',
      requiresAuth: false,
      body: {
        'token': token,
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
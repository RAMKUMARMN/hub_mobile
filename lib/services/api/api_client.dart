// lib/services/api/api_client.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_config.dart';
import 'package:logger/logger.dart';
import '../navigation/navigation_service.dart';

class ApiClient {
  final logger = Logger();
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  static String get baseUrl => AppConfig.apiBaseUrl;
  static const int timeoutSeconds = 120;

  /// Get auth token from storage
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// Get headers with authorization
  Future<Map<String, String>> getHeaders({bool includeAuth = true}) async {
    final headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
    };
    
    if (includeAuth) {
      final token = await getToken();
      if (token != null && token.isNotEmpty) {
        headers["Authorization"] = "Bearer $token";
      } else {
        logger.w('⚠️ No valid token found for authenticated request');
      }
    }
    
    return headers;
  }

  /// Generic request method - THE ONLY HTTP CALLER
  Future<Map<String, dynamic>> request({
    required String method,
    required String endpoint,
    Map<String, dynamic>? body,
    bool requiresAuth = true,
    Map<String, String>? customHeaders,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final headers = await getHeaders(includeAuth: requiresAuth);
      
      if (customHeaders != null) {
        headers.addAll(customHeaders);
      }

      http.Response response;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(url, headers: headers);
          break;
        case 'POST':
          response = await http.post(
            url,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'PUT':
          response = await http.put(
            url,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'PATCH':
          response = await http.patch(
            url,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'DELETE':
          response = await http.delete(url, headers: headers);
          break;
        default:
          return {'success': false, 'error': 'Unsupported method: $method'};
      }

      // Check if unauthorized and try to auto-refresh
      if (response.statusCode == 401 && requiresAuth && endpoint != '/auth/refresh') {
        logger.i('🔄 Token expired (401). Attempting automatic token refresh...');
        final refreshed = await _attemptTokenRefresh();
        if (refreshed) {
          logger.i('✅ Token refreshed successfully. Retrying original request...');
          final retryHeaders = await getHeaders(includeAuth: true);
          if (customHeaders != null) {
            retryHeaders.addAll(customHeaders);
          }

          switch (method.toUpperCase()) {
            case 'GET':
              response = await http.get(url, headers: retryHeaders);
              break;
            case 'POST':
              response = await http.post(
                url,
                headers: retryHeaders,
                body: body != null ? jsonEncode(body) : null,
              );
              break;
            case 'PUT':
              response = await http.put(
                url,
                headers: retryHeaders,
                body: body != null ? jsonEncode(body) : null,
              );
              break;
            case 'PATCH':
              response = await http.patch(
                url,
                headers: retryHeaders,
                body: body != null ? jsonEncode(body) : null,
              );
              break;
            case 'DELETE':
              response = await http.delete(url, headers: retryHeaders);
              break;
          }
        } else {
          logger.w('🔴 Token refresh failed. Forcing logout...');
          await _forceLogout();
          return {
            'success': false,
            'error': 'Session expired. Please log in again.',
            'statusCode': 401,
          };
        }
      }

      return _handleResponse(response);
      
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  /// Attempt to refresh token using refresh_token
  Future<bool> _attemptTokenRefresh() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('auth_refresh_token');
      if (refreshToken == null || refreshToken.isEmpty) {
        return false;
      }

      final refreshUrl = Uri.parse('$baseUrl/auth/refresh');
      final response = await http.post(
        refreshUrl,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({'refresh_token': refreshToken}),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        final String newAccessToken = data['access_token'];
        final String newRefreshToken = data['refresh_token'];

        await prefs.setString('auth_token', newAccessToken);
        await prefs.setString('auth_refresh_token', newRefreshToken);
        return true;
      }
    } catch (e) {
      logger.e('Error during token refresh: $e');
    }
    return false;
  }

  /// Reset session credentials locally and navigate to Login
  Future<void> _forceLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_refresh_token');
    await prefs.remove('user_id');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    await prefs.remove('profile_image_url');
    
    // Redirect to login using NavigationService
    NavigationService.navigateAndClearStack('/login');
  }

  /// Handle all responses uniformly
  Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'error': data['detail'] ?? data['message'] ?? 'Request failed',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Invalid response from server',
        'statusCode': response.statusCode,
      };
    }
  }

  /// ✅ FIXED: Streaming request for AI chat with proper NDJSON parsing
  Future<void> streamRequest({
    required String endpoint,
    required Map<String, dynamic> body,
    required void Function(String chunk) onChunk,
    bool requiresAuth = true,
  }) async {
    try {
      logger.i('📤 Stream request to: $endpoint');
      logger.i('📤 Body: $body');
      
      final request = http.Request(
        'POST',
        Uri.parse('$baseUrl$endpoint'),
      );
      
      final headers = await getHeaders(includeAuth: requiresAuth);
      request.headers.addAll(headers);
      request.body = jsonEncode(body);
      
      logger.i('📤 Headers: ${request.headers}');
      logger.i('📤 Body JSON: ${request.body}');
      
      final response = await request.send();
      
      logger.i('📥 Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final stream = response.stream.transform(utf8.decoder);
        String buffer = ''; // ✅ Buffer to handle partial lines across chunks

        await for (var part in stream) {
          buffer += part;

          // ✅ Only process complete lines; keep the remainder in buffer
          while (buffer.contains('\n')) {
            final newlineIndex = buffer.indexOf('\n');
            final line = buffer.substring(0, newlineIndex).trim();
            buffer = buffer.substring(newlineIndex + 1);

            if (line.isEmpty) continue;

            try {
              final data = jsonDecode(line);
              if (data['response'] != null) {
                onChunk(data['response']);
              } else if (data['error'] != null) {
                onChunk('Error: ${data['error']}');
              }
            } catch (e) {
              logger.w('⚠️ Skipped malformed line: $line');
            }
          }
        }

        // ✅ Handle any trailing data with no final newline
        final trailing = buffer.trim();
        if (trailing.isNotEmpty) {
          try {
            final data = jsonDecode(trailing);
            if (data['response'] != null) {
              onChunk(data['response']);
            }
          } catch (_) {
            // Ignore incomplete trailing data
          }
        }
      } else {
        final errorBody = await response.stream.bytesToString();
        logger.e('❌ Response body: $errorBody');
        onChunk("Error: Server returned ${response.statusCode}");
      }
    } catch (e) {
      logger.e('❌ Stream error: $e');
      onChunk("Error: ${e.toString()}");
    }
  }
}
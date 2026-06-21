// lib/services/api/api_client.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_config.dart';
import 'package:logger/logger.dart';

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

      return _handleResponse(response);
      
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
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
// lib/services/api/api_client.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_config.dart';

class ApiClient {
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
      print('⚠️ No valid token found for authenticated request');
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

  /// Streaming request for AI chat
  Future<void> streamRequest({
    required String endpoint,
    required Map<String, dynamic> body,
    required void Function(String chunk) onChunk,
    bool requiresAuth = true,
  }) async {
    try {
      final request = http.Request(
        'POST',
        Uri.parse('$baseUrl$endpoint'),
      );
      
      final headers = await getHeaders(includeAuth: requiresAuth);
      request.headers.addAll(headers);
      request.body = jsonEncode(body);
      
      final response = await request.send();
      
      if (response.statusCode == 200) {
        final stream = response.stream.transform(utf8.decoder);
        
        await for (var chunk in stream) {
          final lines = chunk.split('\n');
          for (var line in lines) {
            line = line.trim();
            if (line.isNotEmpty) {
              try {
                final data = jsonDecode(line);
                if (data['response'] != null) {
                  onChunk(data['response']);
                }
              } catch (e) {
                if (line.startsWith('Error:')) {
                  onChunk(line);
                }
              }
            }
          }
        }
      } else {
        onChunk("Error: Server returned ${response.statusCode}");
      }
    } catch (e) {
      onChunk("Error: ${e.toString()}");
    }
  }
}
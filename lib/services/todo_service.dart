import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class TodoService {
  static const String baseUrl = 'http://192.168.1.38:8000/api/v1/todos';

  Future<Map<String, String>> get _headers async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<dynamic>> fetchTodos() async {
    final headers = await _headers;
    final response = await http.get(Uri.parse('$baseUrl/'), headers: headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load backlog data');
    }
  }

  Future<void> createTodo(
      String title, String description, DateTime dueDate) async {
    final headers = await _headers;
    final response = await http.post(
      Uri.parse('$baseUrl/'),
      headers: headers,
      body: jsonEncode({
        'title': title,
        'description': description,
        'due_date': dueDate.toUtc().toIso8601String(),
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to append new item to database');
    }
  }

  Future<void> toggleComplete(String id, bool currentlyCompleted) async {
    final headers = await _headers;
    final response = await http.put(
      Uri.parse('$baseUrl/$id/complete'),
      headers: headers,
      body: jsonEncode({
        'completed': !currentlyCompleted, // Sends the inverted toggle state
      }),
    );
    if (response.statusCode != 200) {
      throw Exception(
          'Failed to update task toggle state: ${response.statusCode}');
    }
  }

  Future<void> deleteTodo(String id) async {
    final headers = await _headers;
    final response = await http.delete(
      Uri.parse('$baseUrl/$id'),
      headers: headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to clear item from backend');
    }
  }

  Future<void> registerDeviceWithBackend(String fcmToken) async {
    // Try both AppConfig.apiUrl and modified baseUrl to be safe
    final regUrls = [
      '${AppConfig.apiUrl}/devices/register',
      baseUrl.replaceAll('/todos', '/devices/register'),
    ];

    for (final urlString in regUrls) {
      try {
        final headers = await _headers;
        print("🚀 Registering device with token to: $urlString");
        final response = await http.post(
          Uri.parse(urlString),
          headers: headers,
          body: jsonEncode({
            'device_token': fcmToken,
            'platform': 'android',
          }),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          print(
              "🚀 Notification Sync: Token successfully saved to PostgreSQL!");
          return; // Success
        } else {
          print(
              "❌ Notification Sync Failed ($urlString): ${response.statusCode} - ${response.body}");
        }
      } catch (e) {
        print("❌ Error connecting to backend at $urlString: $e");
      }
    }
    print("❌ All device registration endpoints failed.");
  }
}

// lib/services/api/dashboard_service.dart
import 'api_client.dart';

class DashboardService {
  final ApiClient _client = ApiClient();

  /// Get dashboard data with week offset and feed inclusion
  Future<Map<String, dynamic>> getDashboard({
    int weekOffset = 0,
    bool includeFeeds = true,
  }) async {
    final queryParams = '?week_offset=$weekOffset&include_feeds=$includeFeeds';
    
    final response = await _client.request(
      method: 'GET',
      endpoint: '/dashboard$queryParams',
    );
    
    if (response['success'] == true) {
      return response['data'];
    }
    return response;
  }

  /// Get today's items (tasks, events, etc.)
  Future<Map<String, dynamic>> getTodayItems() async {
    return await _client.request(
      method: 'GET',
      endpoint: '/dashboard/today',
    );
  }

  /// Get recent activity feed
  Future<Map<String, dynamic>> getRecentActivity() async {
    return await _client.request(
      method: 'GET',
      endpoint: '/dashboard/recent',
    );
  }
}
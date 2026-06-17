// lib/services/api/dashboard_api.dart

import 'api_services.dart';

class DashboardApi {
  static Future<Map<String, dynamic>> getDashboard({
    int weekOffset = 0,
    bool includeFeeds = true,
  }) async {
    final queryParams = '?week_offset=$weekOffset&include_feeds=$includeFeeds';
    
    final response = await ApiService.makeRequest(
      method: 'GET',
      endpoint: '/dashboard$queryParams',
    );
    
    if (response['success'] == true) {
      return response['data'];
    }
    return response;
  }
  
  static Future<Map<String, dynamic>> getTodayItems() async {
    return await ApiService.makeRequest(
      method: 'GET',
      endpoint: '/dashboard/today',
    );
  }
  
  static Future<Map<String, dynamic>> getRecentActivity() async {
    return await ApiService.makeRequest(
      method: 'GET',
      endpoint: '/dashboard/recent',
    );
  }
}
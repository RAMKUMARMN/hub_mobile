import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import 'auth_state.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();

  factory ApiService() => _instance;

  late final Dio _dio;

  bool _isRefreshing = false;

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 30),
        headers: const {
          'Content-Type': 'application/json',
        },
        followRedirects: true,
        maxRedirects: 3,
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            final prefs = await SharedPreferences.getInstance();

            final token = prefs.getString('access_token');

            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }

            handler.next(options);
          } catch (e) {
            debugPrint('Request interceptor error: $e');
            handler.next(options);
          }
        },
        onError: (error, handler) async {
          debugPrint(
            'API Error: ${error.requestOptions.method} '
            '${error.requestOptions.path}',
          );

          debugPrint(
            'Status Code: ${error.response?.statusCode}',
          );

          debugPrint(
            'Message: ${error.message}',
          );

          if (error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.receiveTimeout ||
              error.type == DioExceptionType.sendTimeout) {
            return handler.reject(
              DioException(
                requestOptions: error.requestOptions,
                message: 'Request timed out. Please try again.',
              ),
            );
          }

          if (error.type == DioExceptionType.connectionError) {
            return handler.reject(
              DioException(
                requestOptions: error.requestOptions,
                message: 'Unable to connect to the server.',
              ),
            );
          }

          if (error.response?.statusCode == 401 && !_isRefreshing) {
            _isRefreshing = true;

            try {
              final prefs = await SharedPreferences.getInstance();

              final refreshToken = prefs.getString('refresh_token');

              if (refreshToken == null || refreshToken.isEmpty) {
                throw Exception('No refresh token');
              }

              final refreshDio = Dio(
                BaseOptions(
                  baseUrl: AppConfig.apiUrl,
                ),
              );

              final response = await refreshDio.post(
                '/auth/refresh',
                data: {
                  'refresh_token': refreshToken,
                },
              );

              final newAccess = response.data['access_token'] as String?;

              final newRefresh = response.data['refresh_token'] as String?;

              if (newAccess == null || newRefresh == null) {
                throw Exception(
                  'Invalid refresh response',
                );
              }

              await prefs.setString(
                'access_token',
                newAccess,
              );

              await prefs.setString(
                'refresh_token',
                newRefresh,
              );

              final options = error.requestOptions;

              options.headers['Authorization'] = 'Bearer $newAccess';

              final retryResponse = await _dio.fetch(options);

              return handler.resolve(retryResponse);
            } catch (e) {
              debugPrint(
                'Token refresh failed: $e',
              );

              final prefs = await SharedPreferences.getInstance();

              await prefs.remove('access_token');
              await prefs.remove('refresh_token');

              authNotifier.onLogout();

              return handler.reject(
                DioException(
                  requestOptions: error.requestOptions,
                  message: 'Your session has expired. Please sign in again.',
                ),
              );
            } finally {
              _isRefreshing = false;
            }
          }

          handler.next(error);
        },
      ),
    );
  }

  Dio get dio => _dio;
}

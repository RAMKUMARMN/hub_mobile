import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import 'auth_state.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio _dio;
  bool _isRefreshing = false;

  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      headers: {'Content-Type': 'application/json'},
      // Follow redirects (FastAPI trailing-slash 307s) keeping the method + headers
      followRedirects: true,
      maxRedirects: 3,
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401 && !_isRefreshing) {
          _isRefreshing = true;
          try {
            final prefs = await SharedPreferences.getInstance();
            final refreshToken = prefs.getString('refresh_token');
            if (refreshToken != null) {
              final refreshDio = Dio(BaseOptions(baseUrl: AppConfig.apiUrl));
              final res = await refreshDio.post(
                '/auth/refresh',
                data: {'refresh_token': refreshToken},
              );
              final newAccess = res.data['access_token'] as String;
              final newRefresh = res.data['refresh_token'] as String;
              await prefs.setString('access_token', newAccess);
              await prefs.setString('refresh_token', newRefresh);
              // Retry original request with new token
              final opts = error.requestOptions;
              opts.headers['Authorization'] = 'Bearer $newAccess';
              final retryResp = await _dio.fetch(opts);
              _isRefreshing = false;
              return handler.resolve(retryResp);
            }
          } catch (_) {
            // Refresh failed — clear tokens and send user back to login
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('access_token');
            await prefs.remove('refresh_token');
            authNotifier.onLogout();
          }
          _isRefreshing = false;
        }
        handler.next(error);
      },
    ));
  }

  Dio get dio => _dio;
}

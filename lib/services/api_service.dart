import 'package:dio/dio.dart';
import 'token_storage.dart';
import '../config/app_config.dart';
import 'auth_state.dart';
import 'cache_manager.dart';

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
        final token = await TokenStorage.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401 && !_isRefreshing) {
          _isRefreshing = true;
          try {
            final refreshToken = await TokenStorage.getRefreshToken();
            if (refreshToken != null) {
              final refreshDio = Dio(BaseOptions(baseUrl: AppConfig.apiUrl));
              final res = await refreshDio.post(
                '/auth/refresh',
                data: {'refresh_token': refreshToken},
              );
              final newAccess = res.data['access_token'] as String;
              final newRefresh = res.data['refresh_token'] as String;
              await TokenStorage.saveTokens(newAccess, newRefresh);
              // Retry original request with new token
              final opts = error.requestOptions;
              opts.headers['Authorization'] = 'Bearer $newAccess';
              final retryResp = await _dio.fetch(opts);
              _isRefreshing = false;
              return handler.resolve(retryResp);
            }
          } catch (_) {
            // Refresh failed — clear tokens and send user back to login
            await TokenStorage.clearTokens();
            await CacheManager.clearAll();
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

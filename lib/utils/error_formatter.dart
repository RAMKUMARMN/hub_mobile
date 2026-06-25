import 'package:dio/dio.dart';

class ErrorFormatter {
  static String format(dynamic error, {String fallback = 'An unexpected error occurred.'}) {
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.connectionError) {
        return "Unable to connect. Please check your internet connection.";
      }
      if (error.response != null) {
        final statusCode = error.response?.statusCode;
        return "Server error ($statusCode). Please try again later.";
      }
      return "Network error. Please try again when you're online.";
    }
    return fallback;
  }
}

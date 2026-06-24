// lib/mixins/loading_state.dart
import 'package:flutter/material.dart';

mixin LoadingState<T extends StatefulWidget> on State<T> {
  bool _isLoading = false;
  String? _errorMessage;
  
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  
  void setLoading(bool loading) {
    if (mounted) {
      setState(() => _isLoading = loading);
    }
  }
  
  void setError(String? error) {
    if (mounted) {
      setState(() => _errorMessage = error);
    }
  }
  
  void clearError() {
    if (mounted) {
      setState(() => _errorMessage = null);
    }
  }
  
  Future<TResult> withLoading<TResult>(Future<TResult> Function() operation) async {
    setLoading(true);
    clearError();
    
    try {
      final result = await operation();
      return result;
    } catch (e) {
      setError(e.toString());
      rethrow;
    } finally {
      setLoading(false);
    }
  }
  
  Widget buildLoadingIndicator({String? message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message),
          ],
        ],
      ),
    );
  }
  
  Widget buildErrorWidget({VoidCallback? onRetry}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'An error occurred',
            style: TextStyle(color: Colors.red.shade300),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget buildShimmerLoading({
    required Widget child,
    bool isLoading = true,
  }) {
    if (!isLoading) return child;
    
    return ShimmerLoadingWidget(child: child);
  }
}

class ShimmerLoadingWidget extends StatelessWidget {
  final Widget child;
  
  const ShimmerLoadingWidget({super.key, required this.child});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Opacity(
        opacity: 0.5,
        child: child,
      ),
    );
  }
}

mixin FormLoadingState<T extends StatefulWidget> on State<T> {
  final Map<String, bool> _fieldLoading = {};
  bool _isSubmitting = false;
  
  bool isFieldLoading(String field) => _fieldLoading[field] ?? false;
  bool get isSubmitting => _isSubmitting;
  
  void setFieldLoading(String field, bool loading) {
    if (mounted) {
      setState(() => _fieldLoading[field] = loading);
    }
  }
  
  void setSubmitting(bool submitting) {
    if (mounted) {
      setState(() => _isSubmitting = submitting);
    }
  }
  
  Future<TResult> withFieldLoading<TResult>(String field, Future<TResult> Function() operation) async {
    setFieldLoading(field, true);
    try {
      return await operation();
    } finally {
      setFieldLoading(field, false);
    }
  }
  
  Future<TResult> withSubmit<TResult>(Future<TResult> Function() operation) async {
    setSubmitting(true);
    try {
      return await operation();
    } catch (e) {
      rethrow;
    } finally {
      setSubmitting(false);
    }
  }
}
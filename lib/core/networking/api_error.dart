import 'package:dio/dio.dart';

class ApiError {
  ApiError._();

  static String userMessage(Object error) {
    if (error is DioException) {
      return _fromDio(error);
    }
    return 'Something went wrong. Please try again.';
  }

  static String _fromDio(DioException error) {
    final statusCode = error.response?.statusCode;
    final detail = _extractDetail(error);

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'Connection timed out. Please check your internet.';
    }

    if (error.type == DioExceptionType.connectionError) {
      return 'Could not connect to the server. Please try again later.';
    }

    if (statusCode == null) {
      return 'Network error. Please check your connection.';
    }

    return switch (statusCode) {
      400 => detail ?? 'Invalid request. Please check your input.',
      401 => detail ?? 'Invalid credentials. Please try again.',
      403 => 'You don\'t have permission to do this.',
      404 => 'Not found.',
      409 => detail ?? 'This resource already exists.',
      422 => _formatValidationError(error) ?? detail ?? 'Please check your input.',
      429 => 'Too many requests. Please wait a moment.',
      >= 500 => 'Server error. Please try again later.',
      _ => detail ?? 'Something went wrong (error $statusCode).',
    };
  }

  static String? _extractDetail(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final detail = data['detail'];
      if (detail is String) return detail;
    }
    return null;
  }

  static String? _formatValidationError(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final detail = data['detail'];
      if (detail is List && detail.isNotEmpty) {
        final first = detail[0];
        if (first is Map<String, dynamic>) {
          final field = (first['loc'] as List?)?.last;
          final msg = first['msg'];
          if (field != null && msg != null) {
            return '${_humanizeField(field.toString())}: $msg';
          }
        }
      }
    }
    return null;
  }

  static String _humanizeField(String field) {
    return field
        .replaceAll('_', ' ')
        .replaceAllMapped(
          RegExp(r'(^| )(\w)'),
          (m) => '${m[1]}${m[2]!.toUpperCase()}',
        )
        .trim();
  }
}

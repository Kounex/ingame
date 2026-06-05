import 'package:dio/dio.dart';
import 'dart:async';

import '../../l10n/app_localizations.dart';
import 'app_failure.dart';

class ApiError {
  ApiError._();

  static AppFailure toFailure(Object error) {
    if (error is AppFailure) {
      return error;
    }
    if (error is TimeoutException) {
      return const NetworkFailure(AppNetworkFailureType.timeout);
    }
    if (error is DioException) {
      return _fromDio(error);
    }
    return const UnknownFailure();
  }

  static String userMessage(Object error, [AppLocalizations? l10n]) {
    return toFailure(error).userMessage(l10n);
  }

  static AppFailure _fromDio(DioException error) {
    final statusCode = error.response?.statusCode;
    final detail = _extractDetail(error);
    final code = _extractCode(error);

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return const NetworkFailure(AppNetworkFailureType.timeout);
    }

    if (error.type == DioExceptionType.connectionError) {
      return const NetworkFailure(AppNetworkFailureType.connection);
    }

    if (statusCode == null) {
      return const NetworkFailure(AppNetworkFailureType.unknown);
    }

    final validationFailure = _formatValidationError(error);
    if (validationFailure != null) {
      return validationFailure;
    }

    return BackendFailure(statusCode: statusCode, detail: detail, code: code);
  }

  static String? _extractDetail(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final detail = data['detail'];
      if (detail is String) return detail;
    }
    return null;
  }

  static String? _extractCode(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final code = data['code'];
      if (code is String && code.isNotEmpty) return code;
    }
    return null;
  }

  static ValidationFailure? _formatValidationError(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final detail = data['detail'];
      if (detail is List && detail.isNotEmpty) {
        final first = detail[0];
        if (first is Map<String, dynamic>) {
          final field = (first['loc'] as List?)?.last;
          final msg = first['msg'];
          if (field != null && msg != null) {
            return ValidationFailure(
              field: field.toString(),
              message: msg.toString(),
            );
          }
        }
      }
    }
    return null;
  }
}

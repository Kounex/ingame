import 'package:dio/dio.dart';

import '../../l10n/app_localizations.dart';
import '../localization/locale_controller.dart';

class ApiError {
  ApiError._();

  static String userMessage(Object error) {
    final l10n = currentAppLocalizations();
    if (error is DioException) {
      return _fromDio(error, l10n);
    }
    return l10n.errorSomethingWentWrong;
  }

  static String _fromDio(DioException error, AppLocalizations l10n) {
    final statusCode = error.response?.statusCode;
    final detail = _extractDetail(error);

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return l10n.errorConnectionTimedOut;
    }

    if (error.type == DioExceptionType.connectionError) {
      return l10n.errorCouldNotConnect;
    }

    if (statusCode == null) {
      return l10n.errorNetwork;
    }

    return switch (statusCode) {
      400 => detail ?? l10n.errorInvalidRequest,
      401 => detail ?? l10n.errorInvalidCredentials,
      403 => l10n.errorNoPermission,
      404 => l10n.errorNotFound,
      409 => detail ?? l10n.errorAlreadyExists,
      422 => _formatValidationError(error, l10n) ?? detail ?? l10n.errorCheckInput,
      429 => l10n.errorTooManyRequests,
      >= 500 => l10n.errorServer,
      _ => detail ?? l10n.errorUnknownWithCode(statusCode),
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

  static String? _formatValidationError(
    DioException error,
    AppLocalizations l10n,
  ) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final detail = data['detail'];
      if (detail is List && detail.isNotEmpty) {
        final first = detail[0];
        if (first is Map<String, dynamic>) {
          final field = (first['loc'] as List?)?.last;
          final msg = first['msg'];
          if (field != null && msg != null) {
            return l10n.errorValidationFieldMessage(
              _humanizeField(field.toString()),
              msg.toString(),
            );
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

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'package:ingame/core/networking/api_error.dart';

void main() {
  setUp(() {
    Intl.defaultLocale = 'de';
  });

  tearDown(() {
    Intl.defaultLocale = null;
  });

  DioException dioException({
    required int statusCode,
    Object? data,
    DioExceptionType type = DioExceptionType.badResponse,
  }) {
    final request = RequestOptions(path: '/auth/login');
    return DioException(
      requestOptions: request,
      response: Response(
        requestOptions: request,
        statusCode: statusCode,
        data: data,
      ),
      type: type,
    );
  }

  test('maps backend error codes to localized failure messages', () {
    final failure = ApiError.toFailure(
      dioException(
        statusCode: 401,
        data: {
          'detail': 'Invalid email or password',
          'code': 'auth.invalid_credentials',
        },
      ),
    );

    expect(
      failure.userMessage(),
      'Ungültige Anmeldedaten. Bitte versuche es erneut.',
    );
  });

  test('falls back to backend detail when error code is unknown', () {
    final failure = ApiError.toFailure(
      dioException(
        statusCode: 409,
        data: {
          'detail': 'Custom server detail',
          'code': 'custom.unknown_code',
        },
      ),
    );

    expect(failure.userMessage(), 'Custom server detail');
  });

  test('maps revoked Steam login code to relink guidance', () {
    final failure = ApiError.toFailure(
      dioException(
        statusCode: 409,
        data: {
          'detail': 'This Steam login was disconnected.',
          'code': 'auth.steam_relink_required',
        },
      ),
    );

    expect(
      failure.userMessage(),
      'Diese Steam-Anmeldung wurde getrennt. Melde dich mit einer anderen Methode an und verknuepfe Steam anschliessend im Profil erneut.',
    );
  });

  test('maps last auth method guard to explicit disconnect guidance', () {
    final failure = ApiError.toFailure(
      dioException(
        statusCode: 422,
        data: {
          'detail': 'Cannot remove your only login method.',
          'code': 'user.last_auth_method_required',
        },
      ),
    );

    expect(
      failure.userMessage(),
      'Fuege zuerst eine weitere Anmeldemethode hinzu, bevor du diese trennst.',
    );
  });
}

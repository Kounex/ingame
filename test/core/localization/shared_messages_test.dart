import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'package:ingame/core/networking/api_error.dart';
import 'package:ingame/core/utils/validators.dart';

void main() {
  setUp(() {
    Intl.defaultLocale = 'de';
  });

  tearDown(() {
    Intl.defaultLocale = null;
  });

  test('email validator uses German copy', () {
    expect(FormValidators.email(''), 'E-Mail ist erforderlich');
    expect(
      FormValidators.email('not-an-email'),
      'Gib eine gueltige E-Mail-Adresse ein',
    );
  });

  test('api error uses German fallback copy', () {
    final request = RequestOptions(path: '/groups');
    final error = DioException(
      requestOptions: request,
      response: Response(
        requestOptions: request,
        statusCode: 403,
        data: <String, dynamic>{},
      ),
    );

    expect(
      ApiError.userMessage(error),
      'Du hast keine Berechtigung dafuer.',
    );
  });
}

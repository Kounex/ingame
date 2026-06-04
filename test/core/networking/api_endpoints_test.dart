import 'package:flutter_test/flutter_test.dart';
import 'package:ingame/core/networking/api_endpoints.dart';

void main() {
  test('runtime host defaults stay repo-local for development', () {
    expect(ApiEndpoints.baseUrl, 'http://localhost:8000/api/v1');
    expect(ApiEndpoints.webAppBaseUrl, 'http://localhost:8080');
    expect(ApiEndpoints.inviteBaseUrl, 'http://localhost:8080');
  });

  test('websocketUrl derives from the API base URL', () {
    expect(ApiEndpoints.websocketUrl, 'ws://localhost:8000/api/v1/ws');
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:ingame/core/routing/route_names.dart';
import 'package:ingame/core/routing/route_normalization.dart';

void main() {
  test('normalizeRouteLocation keeps only whitelisted auth query params', () {
    expect(
      normalizeRouteLocation(
        '${RoutePaths.login}?foo=bar&from=%2Fjoin%2FABC123%3Futm%3Dcampaign',
      ),
      '${RoutePaths.login}?from=%2Fjoin%2FABC123',
    );
  });

  test('sanitizeRedirectTarget strips stray query params from app routes', () {
    expect(
      sanitizeRedirectTarget('/discover?debug=true'),
      RoutePaths.discover,
    );
  });

  test('sanitizeRedirectTarget rejects auth and onboarding loops', () {
    expect(sanitizeRedirectTarget('/login?from=%2Fprofile'), isNull);
    expect(sanitizeRedirectTarget('/onboarding?from=%2Fprofile'), isNull);
  });
}

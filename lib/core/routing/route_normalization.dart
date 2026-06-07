import 'route_names.dart';

const _redirectQueryKey = 'from';

const Set<String> _redirectCarrierPaths = {
  RoutePaths.login,
  RoutePaths.register,
  RoutePaths.steamAuth,
  RoutePaths.discordAuth,
  RoutePaths.onboarding,
};

const Set<String> _invalidRedirectPaths = {
  RoutePaths.login,
  RoutePaths.register,
  RoutePaths.steamAuth,
  RoutePaths.discordAuth,
  RoutePaths.onboarding,
};

String? normalizeRouteLocation(String? location) {
  final uri = _parseInternalLocation(location);
  if (uri == null) {
    return null;
  }

  final path = _normalizePath(uri.path);
  final queryParameters = <String, String>{};

  if (_redirectCarrierPaths.contains(path)) {
    final redirectTarget = sanitizeRedirectTarget(
      uri.queryParameters[_redirectQueryKey],
    );
    if (redirectTarget != null) {
      queryParameters[_redirectQueryKey] = redirectTarget;
    }
  }

  return Uri(
    path: path,
    queryParameters: queryParameters.isEmpty ? null : queryParameters,
  ).toString();
}

String? sanitizeRedirectTarget(String? location) {
  final normalized = normalizeRouteLocation(location);
  if (normalized == null) {
    return null;
  }

  final path = Uri.parse(normalized).path;
  if (_invalidRedirectPaths.contains(path)) {
    return null;
  }

  return normalized;
}

Uri? _parseInternalLocation(String? location) {
  if (location == null || location.isEmpty) {
    return null;
  }

  final uri = Uri.tryParse(location);
  if (uri == null || uri.hasScheme || uri.hasAuthority) {
    return null;
  }

  return uri;
}

String _normalizePath(String path) {
  if (path.isEmpty) {
    return RoutePaths.home;
  }

  return path.startsWith('/') ? path : '/$path';
}

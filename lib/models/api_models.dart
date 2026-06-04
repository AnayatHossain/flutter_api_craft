
// ────────────────────────────────────────────────────────────────────────────
// Scripts
// ────────────────────────────────────────────────────────────────────────────

import '../utils/enums.dart';

/// A script that runs before the request is sent, or after the response arrives.
/// Mirrors Postman's Pre-request Script / Post-response Script tabs.
class ApiScript {
  /// Called before the request fires.
  /// Receives mutable [headers], [params], and [body] maps so the script can
  /// modify them in place.
  final Future<void> Function({
  required Map<String, String> headers,
  required Map<String, String> params,
  required Map<String, dynamic> body,
  })? preRequest;

  /// Called after the response arrives.
  /// Receives [statusCode], [responseBody], and the same mutable maps.
  final Future<void> Function({
  required int statusCode,
  required dynamic responseBody,
  required Map<String, String> headers,
  })? postResponse;

  const ApiScript({
    this.preRequest,
    this.postResponse,
  });
}

// ────────────────────────────────────────────────────────────────────────────
// Cookies
// ────────────────────────────────────────────────────────────────────────────

/// Cookie jar configuration.
class ApiCookies {
  /// If true the package manages cookies automatically across requests
  /// (stores Set-Cookie, sends Cookie header).
  final bool enableCookieJar;

  /// Override: explicitly send these cookies on this request.
  final Map<String, String>? extraCookies;

  /// If true, cookies received in this response are NOT persisted.
  final bool disableCookiePersistence;

  const ApiCookies({
    this.enableCookieJar = false,
    this.extraCookies,
    this.disableCookiePersistence = false,
  });
}

// ────────────────────────────────────────────────────────────────────────────
// Query Params
// ────────────────────────────────────────────────────────────────────────────

/// Query parameters appended to the URL.
class ApiParams {
  /// Simple key→value params.  E.g. {"page": "1", "limit": "10"}
  final Map<String, String>? query;

  /// Multi-value params. E.g. {"tags": ["flutter", "dart"]}
  final Map<String, List<String>>? multiQuery;

  const ApiParams({
    this.query,
    this.multiQuery,
  });

  const ApiParams.simple(Map<String, String> params)
      : this(query: params);
}

// ────────────────────────────────────────────────────────────────────────────
// Navigation
// ────────────────────────────────────────────────────────────────────────────

/// What to do after a successful API response.
class ApiSuccessNavigation {
  final NavigationAction action;

  /// Named route for pushNamed / pushReplacement / pushAndRemoveUntil.
  final String? routeName;

  /// Arguments to pass to the named route.
  final Object? arguments;

  /// Widget builder for offAll (if no routeName).
  final dynamic Function()? widgetBuilder;

  /// Only navigate when this extra condition passes (receives response body).
  final bool Function(dynamic responseBody)? condition;

  const ApiSuccessNavigation({
    this.action = NavigationAction.none,
    this.routeName,
    this.arguments,
    this.widgetBuilder,
    this.condition,
  });

  /// Pop back one screen on success.
  const ApiSuccessNavigation.pop()
      : this(action: NavigationAction.pop);

  /// Push a named route on success.
  const ApiSuccessNavigation.push(String route, {Object? args})
      : this(
    action: NavigationAction.pushNamed,
    routeName: route,
    arguments: args,
  );

  /// Replace current screen with a named route on success.
  const ApiSuccessNavigation.replace(String route, {Object? args})
      : this(
    action: NavigationAction.pushReplacement,
    routeName: route,
    arguments: args,
  );

  /// Remove all screens and push a named route on success.
  const ApiSuccessNavigation.offAll(String route, {Object? args})
      : this(
    action: NavigationAction.offAll,
    routeName: route,
    arguments: args,
  );
}

// ────────────────────────────────────────────────────────────────────────────
// Snackbar config
// ────────────────────────────────────────────────────────────────────────────

/// Customize the success / error snackbars shown by the package.
class ApiSnackBarConfig {
  // ── Success ──
  final bool showOnSuccess;
  final String? successTitle;
  final String? successMessageOverride; // null → use response["message"]
  final String? successMessageKey;      // key to read from response body

  // ── Error ──
  final bool showOnError;
  final String? errorTitle;
  final String? errorMessageOverride;
  final String? errorMessageKey;

  // ── Styling ──
  final dynamic backgroundColor; // Color
  final dynamic successBackgroundColor;
  final dynamic errorBackgroundColor;
  final dynamic textColor;
  final dynamic position; // SnackPosition
  final Duration duration;
  final double borderRadius;
  final dynamic margin; // EdgeInsets

  const ApiSnackBarConfig({
    this.showOnSuccess = false,
    this.successTitle = 'Success',
    this.successMessageOverride,
    this.successMessageKey = 'message',
    this.showOnError = false,
    this.errorTitle = 'Error',
    this.errorMessageOverride,
    this.errorMessageKey = 'message',
    this.backgroundColor,
    this.successBackgroundColor,
    this.errorBackgroundColor,
    this.textColor,
    this.position,
    this.duration = const Duration(seconds: 3),
    this.borderRadius = 12,
    this.margin,
  });
}

// ────────────────────────────────────────────────────────────────────────────
// HTTP Settings  (mirrors Postman's Settings tab)
// ────────────────────────────────────────────────────────────────────────────

class ApiSettings {
  final bool followRedirects;
  final int maxRedirects;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final bool verifySslCertificate;

  const ApiSettings({
    this.followRedirects = true,
    this.maxRedirects = 10,
    this.connectTimeout = const Duration(seconds: 30),
    this.receiveTimeout = const Duration(seconds: 30),
    this.verifySslCertificate = true,
  });
}
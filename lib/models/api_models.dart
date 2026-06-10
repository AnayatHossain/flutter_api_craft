import 'package:flutter/cupertino.dart';
import 'package:get/get_navigation/src/snackbar/snackbar.dart';
import 'package:flutter_api_craft/utils/enums.dart';

// ────────────────────────────────────────────────────────────────────────────
// Scripts
// ────────────────────────────────────────────────────────────────────────────

/// Lifecycle hooks that run before the request is sent or after the
/// response arrives — identical to Postman's Pre-request Script and
/// Post-response Script tabs.
///
/// ```dart
/// ApiScript(
///   preRequest: ({required headers, required params, required body}) async {
///     headers['X-Timestamp'] = DateTime.now().millisecondsSinceEpoch.toString();
///   },
///   postResponse: ({required statusCode, required responseBody, required headers}) async {
///     if (statusCode == 401) {
///       // handle token expiry
///     }
///   },
/// )
/// ```
class ApiScript {
  /// Called before the HTTP request is sent.
  ///
  /// Receives mutable [headers], [params], and [body] maps. Any changes made
  /// to these maps are forwarded to the actual request.
  final Future<void> Function({
  required Map<String, String> headers,
  required Map<String, String> params,
  required Map<String, dynamic> body,
  })? preRequest;

  /// Called after the HTTP response is received.
  ///
  /// Receives the `statusCode`, the parsed `responseBody`, and the
  /// response `headers`.
  final Future<void> Function({
  required int statusCode,
  required dynamic responseBody,
  required Map<String, String> headers,
  })? postResponse;

  /// Creates an [ApiScript] with optional pre-request and post-response hooks.
  const ApiScript({
    this.preRequest,
    this.postResponse,
  });
}

// ────────────────────────────────────────────────────────────────────────────
// Cookies
// ────────────────────────────────────────────────────────────────────────────

/// Cookie jar configuration for a request.
///
/// ```dart
/// // Enable automatic cookie management
/// ApiCookies(enableCookieJar: true)
///
/// // Send extra cookies manually
/// ApiCookies(extraCookies: {'session_id': 'abc123'})
/// ```
class ApiCookies {
  /// When `true`, the package automatically stores cookies from `Set-Cookie`
  /// response headers and re-sends them as `Cookie` headers on subsequent
  /// requests to the same domain.
  final bool enableCookieJar;

  /// Extra cookies to send on this specific request, regardless of the jar.
  final Map<String, String>? extraCookies;

  /// When `true`, cookies received in this response are not stored in the jar.
  final bool disableCookiePersistence;

  /// Creates an [ApiCookies] configuration.
  const ApiCookies({
    this.enableCookieJar = false,
    this.extraCookies,
    this.disableCookiePersistence = false,
  });
}

// ────────────────────────────────────────────────────────────────────────────
// Query Params
// ────────────────────────────────────────────────────────────────────────────

/// Query parameters appended to the request URL.
///
/// ```dart
/// // Simple key/value params: ?page=1&limit=20
/// ApiParams.simple({'page': '1', 'limit': '20'})
///
/// // Multi-value params: ?tags=flutter&tags=dart
/// ApiParams(multiQuery: {'tags': ['flutter', 'dart']})
///
/// // Combined
/// ApiParams(
///   query: {'page': '1'},
///   multiQuery: {'tags': ['flutter', 'dart']},
/// )
/// ```
class ApiParams {
  /// Simple key→value query parameters.
  final Map<String, String>? query;

  /// Multi-value query parameters where one key maps to multiple values.
  final Map<String, List<String>>? multiQuery;

  /// Creates an [ApiParams] with optional [query] and [multiQuery] maps.
  const ApiParams({
    this.query,
    this.multiQuery,
  });

  /// Convenience constructor for a simple flat map of query parameters.
  const ApiParams.simple(Map<String, String> params)
      : this(query: params);
}

// ────────────────────────────────────────────────────────────────────────────
// Navigation
// ────────────────────────────────────────────────────────────────────────────

/// Describes what navigation action to take after a successful API response.
///
/// ```dart
/// // Pop back on success
/// ApiSuccessNavigation.pop()
///
/// // Push a named route on success
/// ApiSuccessNavigation.push('/home')
///
/// // Replace current screen on success
/// ApiSuccessNavigation.replace('/dashboard')
///
/// // Clear stack and push on success
/// ApiSuccessNavigation.offAll('/login')
///
/// // Conditional navigation
/// ApiSuccessNavigation(
///   action: NavigationAction.pop,
///   condition: (body) => body['verified'] == true,
/// )
/// ```
class ApiSuccessNavigation {
  /// The navigation action to perform.
  final NavigationAction action;

  /// Named route for [NavigationAction.pushNamed],
  /// [NavigationAction.pushReplacement], [NavigationAction.pushAndRemoveUntil],
  /// and [NavigationAction.offAll].
  final String? routeName;

  /// Arguments forwarded to the new route via `Get.toNamed(arguments: ...)`.
  final Object? arguments;

  /// Widget builder used with [NavigationAction.offAll] when no [routeName]
  /// is provided.
  final dynamic Function()? widgetBuilder;

  /// Optional guard: navigation only happens when this returns `true`.
  ///
  /// Receives the parsed response body so you can check specific fields,
  /// e.g. `(body) => body['verified'] == true`.
  final bool Function(dynamic responseBody)? condition;

  /// Creates an [ApiSuccessNavigation] with full control.
  const ApiSuccessNavigation({
    this.action = NavigationAction.none,
    this.routeName,
    this.arguments,
    this.widgetBuilder,
    this.condition,
  });

  /// Calls `Get.back()` after a successful response.
  const ApiSuccessNavigation.pop()
      : this(action: NavigationAction.pop);

  /// Calls `Get.toNamed(route)` after a successful response.
  const ApiSuccessNavigation.push(String route, {Object? args})
      : this(
    action: NavigationAction.pushNamed,
    routeName: route,
    arguments: args,
  );

  /// Calls `Get.offNamed(route)` after a successful response.
  const ApiSuccessNavigation.replace(String route, {Object? args})
      : this(
    action: NavigationAction.pushReplacement,
    routeName: route,
    arguments: args,
  );

  /// Calls `Get.offAllNamed(route)` after a successful response.
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

/// Full customization for the success and error snackbars shown by the package.
///
/// ```dart
/// ApiSnackBarConfig(
///   successTitle: 'Done!',
///   successMessageKey: 'message',   // reads response body["message"]
///   errorTitle: 'Oops',
///   successBackgroundColor: Colors.green,
///   errorBackgroundColor: Colors.red,
///   textColor: Colors.white,
///   duration: Duration(seconds: 4),
/// )
/// ```
class ApiSnackBarConfig {
  /// Whether to show a snackbar on a successful response.
  final bool showOnSuccess;

  /// Title of the success snackbar. Defaults to `"Success"`.
  final String? successTitle;

  /// Fixed message for the success snackbar.
  /// When null, the value at [successMessageKey] is read from the response body.
  final String? successMessageOverride;

  /// Key used to read the success message from the response body Map.
  /// Defaults to `"message"`.
  final String? successMessageKey;

  /// Whether to show a snackbar on a failed response.
  final bool showOnError;

  /// Title of the error snackbar. Defaults to `"Error"`.
  final String? errorTitle;

  /// Fixed message for the error snackbar.
  /// When null, `ApiResponse.errorMessage` is used.
  final String? errorMessageOverride;

  /// Key used to read the error message from the response body Map.
  /// Defaults to `"message"`.
  final String? errorMessageKey;

  /// Background color for both snackbars (fallback when the specific
  /// success/error color is not set).
  final Color? backgroundColor;
  /// Background color for the success snackbar. Overrides [backgroundColor].
  final Color? successBackgroundColor;

  /// Background color for the error snackbar. Overrides [backgroundColor].
  final Color? errorBackgroundColor;

  /// Text color for both snackbars.
  final Color? textColor;

  /// Snackbar position (`SnackPosition.TOP` or `SnackPosition.BOTTOM`).
  /// Defaults to `SnackPosition.BOTTOM`.
  final SnackPosition? position;

  /// How long the snackbar stays visible. Defaults to 3 seconds.
  final Duration duration;

  /// Corner radius of the snackbar. Defaults to `12`.
  final double borderRadius;

  /// Outer margin of the snackbar. Defaults to `EdgeInsets.all(12)`.
  final EdgeInsets? margin;

  /// Creates an [ApiSnackBarConfig] with the provided customizations.
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
// HTTP Settings
// ────────────────────────────────────────────────────────────────────────────

/// Low-level HTTP settings that mirror Postman's Settings tab.
///
/// ```dart
/// ApiSettings(
///   followRedirects: true,
///   maxRedirects: 5,
///   connectTimeout: Duration(seconds: 10),
///   receiveTimeout: Duration(seconds: 30),
///   verifySslCertificate: true,
/// )
/// ```
class ApiSettings {
  /// Follow HTTP 3xx redirects automatically. Defaults to `true`.
  final bool followRedirects;

  /// Maximum number of redirects to follow. Defaults to `10`.
  final int maxRedirects;

  /// How long to wait for the connection to be established.
  final Duration connectTimeout;

  /// How long to wait for the full response to arrive.
  final Duration receiveTimeout;

  /// Verify SSL/TLS certificates. Defaults to `true`.
  final bool verifySslCertificate;

  /// Creates an [ApiSettings] instance.
  const ApiSettings({
    this.followRedirects = true,
    this.maxRedirects = 10,
    this.connectTimeout = const Duration(seconds: 30),
    this.receiveTimeout = const Duration(seconds: 30),
    this.verifySslCertificate = true,
  });
}
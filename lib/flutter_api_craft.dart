/// A comprehensive Flutter API client — the Postman of Flutter packages.
///
/// All HTTP configuration in one constructor call:
///
/// ```dart
/// import 'package:flutter_api_craft/flutter_api_craft.dart';
///
/// final response = await FlutterApiCraft(
///   baseUrl: 'https://api.example.com',
///   path: '/auth/login',
///   apiType: ApiType.post,
///   apiBody: ApiBody.json({'email': 'user@example.com', 'password': '123456'}),
///   enableLoading: true,
///   enableApiSuccessResponseGetSnackBar: true,
///   enableApiErrorResponseGetSnackBar: true,
///   apiSuccessResponseNavigation: ApiSuccessNavigation.pop(),
/// ).call();
///
/// if (response.isSuccess) {
///   final token = response['data']['token'];
/// }
/// ```
///
/// ## Features
///
/// - **All HTTP methods**: GET, POST, PUT, PATCH, DELETE, HEAD, OPTIONS
/// - **All body types**: JSON, form-data, URL-encoded, XML, HTML, GraphQL, binary
/// - **All auth types**: Bearer, Basic, JWT, OAuth 1/2, API Key, Digest, Hawk,
///   AWS Signature, NTLM, Akamai EdgeGrid
/// - **Params**: simple and multi-value query parameters
/// - **Scripts**: pre-request and post-response hooks
/// - **Cookies**: automatic cookie jar per domain
/// - **Loading**: `flutter_easyloading` overlay
/// - **Snackbars**: GetX snackbars with full colour/message customization
/// - **Navigation**: automatic GetX navigation after success
/// - **Retry**: configurable retry count with delay
/// - **401 refresh**: automatic token refresh and single retry
/// - **Testing**: injectable [http.Client] for unit tests
library flutter_api_craft;

// ── Public API ────────────────────────────────────────────────────────────────
export 'utils/enums.dart';
export 'models/api_authorization.dart';
export 'models/api_body.dart';
export 'models/api_models.dart';
export 'models/api_response.dart';
export 'interceptors/cookie_manager.dart';

// ── Internal ──────────────────────────────────────────────────────────────────
import 'dart:convert';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart' as getx;
import 'package:http/http.dart' as http;

import 'configs/request_builder.dart';
import 'interceptors/cookie_manager.dart';
import 'models/api_authorization.dart';
import 'models/api_body.dart';
import 'models/api_models.dart';
import 'models/api_response.dart';
import 'utils/enums.dart';

/// The main entry point for all API calls in the `flutter_api_craft` package.
///
/// Create an instance, configure it, then call [call] to execute the request.
/// The constructor accepts every option you'd find in Postman, so the complete
/// call configuration lives in one place.
///
/// ```dart
/// // GET request
/// final res = await FlutterApiCraft(
///   baseUrl: 'https://jsonplaceholder.typicode.com',
///   path: '/posts',
///   apiParams: ApiParams.simple({'_limit': '5'}),
/// ).call();
///
/// // POST with Bearer auth + loading + snackbar + auto-pop
/// final res = await FlutterApiCraft(
///   baseUrl: 'https://api.example.com',
///   path: '/auth/login',
///   apiType: ApiType.post,
///   apiAuthorization: ApiAuthorization.bearer(token),
///   apiBody: ApiBody.json({'email': email, 'password': pass}),
///   enableLoading: true,
///   enableApiSuccessResponseGetSnackBar: true,
///   enableApiErrorResponseGetSnackBar: true,
///   apiSuccessResponseNavigation: ApiSuccessNavigation.pop(),
/// ).call();
///
/// // Multipart form-data (profile photo upload)
/// final res = await FlutterApiCraft(
///   baseUrl: 'https://api.example.com',
///   path: '/users/update-profile',
///   apiType: ApiType.put,
///   apiAuthorization: ApiAuthorization.bearer(token),
///   apiBody: ApiBody.formData(
///     fields: {'fullName': 'John Doe'},
///     files: [ApiFile(fieldName: 'avatar', file: pickedFile)],
///   ),
///   enableLoading: true,
/// ).call();
/// ```
class FlutterApiCraft {
  // ── Core ──────────────────────────────────────────────────────────────────

  /// Base URL for all requests, e.g. `"https://api.example.com"`.
  final String baseUrl;

  /// Request path appended to [baseUrl], e.g. `"/auth/login"`.
  ///
  /// If this starts with `"http"` it is used as an absolute URL and
  /// [baseUrl] is ignored.
  final String path;

  /// HTTP method. Defaults to [ApiType.get].
  final ApiType apiType;

  // ── Request building ──────────────────────────────────────────────────────

  /// Request body. Supports none, JSON, form-data, URL-encoded, GraphQL,
  /// binary, XML, HTML, and JavaScript content types.
  final ApiBody? apiBody;

  /// Extra request headers merged with the authorization headers.
  final Map<String, String> apiHeaders;

  /// Authorization configuration. Supports all Postman auth types.
  final ApiAuthorization? apiAuthorization;

  /// Query parameters appended to the URL.
  final ApiParams? apiParams;

  /// Pre-request and post-response lifecycle hooks.
  final ApiScript? apiScripts;

  /// Cookie jar configuration for automatic cookie management.
  final ApiCookies? apiCookies;

  /// Low-level HTTP settings (redirects, timeouts, SSL).
  final ApiSettings apiSettings;

  // ── UX / Feedback ─────────────────────────────────────────────────────────

  /// Show a `flutter_easyloading` overlay while the request is in-flight.
  final bool enableLoading;

  /// Message displayed in the loading overlay. Defaults to `"Loading..."`.
  final String loadingMessage;

  /// Print the raw response body to the debug console.
  final bool enableBodyResponseDebugPrint;

  /// Print a formatted success log to the debug console.
  final bool enableApiSuccessResponseDebugPrint;

  /// Show a GetX snackbar on a successful (2xx + success) response.
  final bool enableApiSuccessResponseGetSnackBar;

  /// Show a GetX snackbar on a failed response.
  final bool enableApiErrorResponseGetSnackBar;

  /// Full customization of the success and error snackbars.
  final ApiSnackBarConfig? snackBarConfig;

  /// Navigation action to perform after a successful response.
  final ApiSuccessNavigation? apiSuccessResponseNavigation;

  // ── Retry / Refresh ───────────────────────────────────────────────────────

  /// When the server returns 401, this callback is invoked to refresh the
  /// token. If it returns a non-null string the request is retried once with
  /// the new token as a Bearer token.
  final Future<String?> Function()? onUnauthorizedRefreshToken;

  /// Number of automatic retries on failure. Defaults to `0` (no retries).
  final int retryCount;

  /// Delay between retry attempts. Defaults to 1 second.
  final Duration retryDelay;

  // ── Lifecycle callbacks ───────────────────────────────────────────────────

  /// Called with the final [ApiResponse] when the request succeeds.
  final void Function(ApiResponse response)? onSuccess;

  /// Called with the final [ApiResponse] when the request fails.
  final void Function(ApiResponse response)? onError;

  /// Called after the request completes, regardless of outcome.
  final void Function()? onComplete;

  // ── Testing ───────────────────────────────────────────────────────────────

  /// Optional HTTP client for unit testing.
  ///
  /// Inject a `MockClient` (from the `http` package) here to test your
  /// controllers without making real network calls.
  ///
  /// ```dart
  /// FlutterApiCraft(
  ///   baseUrl: 'https://api.example.com',
  ///   path: '/login',
  ///   httpClient: MockClient((request) async {
  ///     return http.Response('{"success": true, "token": "abc"}', 200);
  ///   }),
  /// )
  /// ```
  final http.Client? httpClient;

  // ── Constructor ───────────────────────────────────────────────────────────

  /// Creates a [FlutterApiCraft] instance.
  ///
  /// Only [baseUrl] and [path] are required. All other parameters have
  /// sensible defaults.
  const FlutterApiCraft({
    required this.baseUrl,
    required this.path,
    this.apiType = ApiType.get,
    this.apiBody,
    this.apiHeaders = const {},
    this.apiAuthorization,
    this.apiParams,
    this.apiScripts,
    this.apiCookies,
    this.apiSettings = const ApiSettings(),
    this.enableLoading = false,
    this.loadingMessage = 'Loading...',
    this.enableBodyResponseDebugPrint = false,
    this.enableApiSuccessResponseDebugPrint = false,
    this.enableApiSuccessResponseGetSnackBar = false,
    this.enableApiErrorResponseGetSnackBar = false,
    this.snackBarConfig,
    this.apiSuccessResponseNavigation,
    this.onUnauthorizedRefreshToken,
    this.retryCount = 0,
    this.retryDelay = const Duration(seconds: 1),
    this.onSuccess,
    this.onError,
    this.onComplete,
    this.httpClient,
  });

  // ── Public API ────────────────────────────────────────────────────────────

  /// Executes the HTTP request and returns an [ApiResponse].
  ///
  /// Never throws — all errors are captured and returned in the response.
  Future<ApiResponse> call() async {
    try {
      if (enableLoading) EasyLoading.show(status: loadingMessage);
      final response = await _executeWithRetry(attempt: 0);
      if (enableLoading) await EasyLoading.dismiss();
      _handleFeedback(response);
      onComplete?.call();
      return response;
    } catch (e, stack) {
      if (enableLoading) await EasyLoading.dismiss();
      dev.log('FlutterApiCraft error: $e', stackTrace: stack, name: 'flutter_api_craft');
      final errResponse = ApiResponse(
        statusCode: 0,
        rawBody: '',
        data: null,
        isSuccess: false,
        headers: {},
        errorMessage: e.toString(),
        exception: e,
      );
      onError?.call(errResponse);
      onComplete?.call();
      return errResponse;
    }
  }

  // ── Retry logic ───────────────────────────────────────────────────────────

  Future<ApiResponse> _executeWithRetry({required int attempt}) async {
    final response = await _executeOnce();

    if (response.statusCode == 401 && onUnauthorizedRefreshToken != null) {
      final newToken = await onUnauthorizedRefreshToken!();
      if (newToken != null) {
        return FlutterApiCraft(
          baseUrl: baseUrl,
          path: path,
          apiType: apiType,
          apiBody: apiBody,
          apiHeaders: apiHeaders,
          apiAuthorization: ApiAuthorization.bearer(newToken),
          apiParams: apiParams,
          apiScripts: apiScripts,
          apiCookies: apiCookies,
          apiSettings: apiSettings,
          httpClient: httpClient,
        )._executeOnce();
      }
    }

    if (!response.isSuccess && attempt < retryCount) {
      await Future.delayed(retryDelay);
      return _executeWithRetry(attempt: attempt + 1);
    }

    return response;
  }

  // ── Single execution ──────────────────────────────────────────────────────

  Future<ApiResponse> _executeOnce() async {
    final client = httpClient ?? http.Client();

    try {
      final mutableHeaders = Map<String, String>.from(apiHeaders);
      final mutableParams = Map<String, String>.from(apiParams?.query ?? {});
      final mutableBody = <String, dynamic>{};

      if (apiBody?.rawData is Map) {
        mutableBody.addAll(
          Map<String, dynamic>.from(apiBody!.rawData as Map<String, dynamic>),
        );
      }

      if (apiScripts?.preRequest != null) {
        await apiScripts!.preRequest!(
          headers: mutableHeaders,
          params: mutableParams,
          body: mutableBody,
        );
      }

      final finalParams = ApiParams(
        query: {...?apiParams?.query, ...mutableParams},
        multiQuery: apiParams?.multiQuery,
      );

      final request = await RequestBuilder.build(
        baseUrl: baseUrl,
        path: path,
        method: apiType,
        headers: mutableHeaders,
        body: apiBody,
        params: finalParams,
        authorization: apiAuthorization,
        cookies: apiCookies,
      );

      final streamedResponse =
          await client.send(request).timeout(apiSettings.receiveTimeout);
      final responseString = await streamedResponse.stream.bytesToString();
      final responseHeaders = streamedResponse.headers;

      CookieManager.instance.handleResponseCookies(
        request.url.host,
        responseHeaders,
        apiCookies,
      );

      dynamic parsedBody;
      try {
        parsedBody = jsonDecode(responseString);
      } catch (_) {
        parsedBody = responseString;
      }

      if (enableBodyResponseDebugPrint) {
        dev.log(
          '🌐 [$path] ${streamedResponse.statusCode}\n$responseString',
          name: 'flutter_api_craft',
        );
      }

      if (apiScripts?.postResponse != null) {
        await apiScripts!.postResponse!(
          statusCode: streamedResponse.statusCode,
          responseBody: parsedBody,
          headers: Map<String, String>.from(responseHeaders),
        );
      }

      final code = streamedResponse.statusCode;
      final isSuccessCode = code >= 200 && code < 300;
      var successFlag = isSuccessCode;

      if (parsedBody is Map && parsedBody.containsKey('success')) {
        successFlag = isSuccessCode && parsedBody['success'] == true;
      }

      String? errorMsg;
      if (!successFlag) {
        errorMsg = _extractMessage(parsedBody) ?? 'Request failed ($code)';
      }

      if (enableApiSuccessResponseDebugPrint && successFlag) {
        dev.log('✅ [$path] $code', name: 'flutter_api_craft');
      }

      final apiResponse = ApiResponse(
        statusCode: code,
        rawBody: responseString,
        data: parsedBody,
        isSuccess: successFlag,
        headers: Map<String, String>.from(responseHeaders),
        errorMessage: errorMsg,
      );

      if (successFlag) {
        onSuccess?.call(apiResponse);
      } else {
        onError?.call(apiResponse);
      }

      return apiResponse;
    } on Exception catch (e) {
      return ApiResponse(
        statusCode: 0,
        rawBody: '',
        data: null,
        isSuccess: false,
        headers: {},
        errorMessage: e.toString(),
        exception: e,
      );
    } finally {
      if (httpClient == null) client.close();
    }
  }

  // ── Feedback ──────────────────────────────────────────────────────────────

  void _handleFeedback(ApiResponse response) {
    final cfg = snackBarConfig ?? const ApiSnackBarConfig();

    if (response.isSuccess) {
      if (enableApiSuccessResponseGetSnackBar) {
        final msg = cfg.successMessageOverride ??
            (response.data is Map
                ? response.data[cfg.successMessageKey ?? 'message']?.toString()
                : null) ??
            'Success';

        getx.Get.snackbar(
          cfg.successTitle ?? 'Success',
          msg,
          // ✅ Cast নেই, সরাসরি use করো
          backgroundColor:
          cfg.successBackgroundColor ?? cfg.backgroundColor ?? Colors.green,
          colorText: cfg.textColor ?? Colors.white,
          snackPosition: cfg.position ?? getx.SnackPosition.BOTTOM,
          duration: cfg.duration,
          borderRadius: cfg.borderRadius,
          margin: cfg.margin ?? const EdgeInsets.all(12),
        );
      }
      _handleNavigation(response);
    } else {
      if (enableApiErrorResponseGetSnackBar) {
        final msg = cfg.errorMessageOverride ??
            response.errorMessage ??
            'Something went wrong';

        getx.Get.snackbar(
          cfg.errorTitle ?? 'Error',
          msg,
          backgroundColor:
          cfg.errorBackgroundColor ?? cfg.backgroundColor ?? Colors.red,
          colorText: cfg.textColor ?? Colors.white,
          snackPosition: cfg.position ?? getx.SnackPosition.BOTTOM,
          duration: cfg.duration,
          borderRadius: cfg.borderRadius,
          margin: cfg.margin ?? const EdgeInsets.all(12),
        );
      }
    }
  }

  void _handleNavigation(ApiResponse response) {
    final nav = apiSuccessResponseNavigation;
    if (nav == null) return;
    if (nav.condition != null && !nav.condition!(response.data)) return;

    switch (nav.action) {
      case NavigationAction.none:
        break;
      case NavigationAction.pop:
        getx.Get.back();
      case NavigationAction.popUntil:
        if (nav.routeName != null) {
          getx.Get.until((route) => route.settings.name == nav.routeName);
        }
      case NavigationAction.pushNamed:
        if (nav.routeName != null) {
          getx.Get.toNamed(nav.routeName!, arguments: nav.arguments);
        }
      case NavigationAction.pushReplacement:
        if (nav.routeName != null) {
          getx.Get.offNamed(nav.routeName!, arguments: nav.arguments);
        }
      case NavigationAction.pushAndRemoveUntil:
        if (nav.routeName != null) {
          getx.Get.offAllNamed(nav.routeName!, arguments: nav.arguments);
        }
      case NavigationAction.offAll:
        if (nav.routeName != null) {
          getx.Get.offAllNamed(nav.routeName!, arguments: nav.arguments);
        } else if (nav.widgetBuilder != null) {
          getx.Get.offAll(nav.widgetBuilder!);
        }
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String? _extractMessage(dynamic body) {
    if (body is Map) {
      for (final key in ['message', 'error', 'errors', 'detail', 'msg']) {
        if (body[key] != null) return body[key].toString();
      }
    }
    return null;
  }
}

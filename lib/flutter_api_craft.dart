import 'dart:convert';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_api_craft/utils/enums.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart' as getx;
import 'package:http/http.dart' as http;

import '../interceptors/cookie_manager.dart';
import '../models/api_authorization.dart';
import '../models/api_body.dart';
import '../models/api_models.dart';
import '../models/api_response.dart';
import 'configs/request_builder.dart';

/// The main entry point for all API calls.
///
/// ```dart
/// final response = await FlutterApiCraft(
///   baseUrl: 'https://api.example.com',
///   path: '/auth/login',
///   apiType: ApiType.post,
///   apiBody: ApiBody.json({'email': 'a@b.com', 'password': '123456'}),
///   enableLoading: true,
///   enableApiSuccessResponseGetSnackBar: true,
///   apiSuccessResponseNavigation: ApiSuccessNavigation.pop(),
/// ).call();
/// ```
class FlutterApiCraft {
  // ── Core ──────────────────────────────────────────────────────────────────

  /// Base URL for the request. E.g. `"https://api.example.com"`
  final String baseUrl;

  /// Path (appended to baseUrl). Can also be a full URL.
  /// E.g. `"/auth/login"` or `"https://other.domain/endpoint"`
  final String path;

  /// HTTP method.
  final ApiType apiType;

  // ── Request building ──────────────────────────────────────────────────────

  /// Request body (none, JSON, form-data, urlencoded, binary, GraphQL).
  final ApiBody? apiBody;

  /// Extra request headers merged with defaults + auth headers.
  final Map<String, String> apiHeaders;

  /// Authorization configuration (Bearer, Basic, OAuth2, API Key, etc.).
  final ApiAuthorization? apiAuthorization;

  /// Query parameters added to the URL.
  final ApiParams? apiParams;

  /// Pre-request and post-response scripts.
  final ApiScript? apiScripts;

  /// Cookie jar configuration.
  final ApiCookies? apiCookies;

  /// HTTP-level settings (redirects, SSL, timeouts).
  final ApiSettings apiSettings;

  // ── UX / Feedback ─────────────────────────────────────────────────────────

  /// Show a loading overlay while the request is in-flight.
  final bool enableLoading;

  /// Loading overlay message.
  final String loadingMessage;

  /// Print the raw response body to the debug console.
  final bool enableBodyResponseDebugPrint;

  /// Print a formatted success log to the debug console.
  final bool enableApiSuccessResponseDebugPrint;

  /// Show a GetX snackbar on success.
  final bool enableApiSuccessResponseGetSnackBar;

  /// Show a GetX snackbar on error.
  final bool enableApiErrorResponseGetSnackBar;

  /// Full snackbar customization (titles, colors, message keys, etc.).
  final ApiSnackBarConfig? snackBarConfig;

  /// Navigate after a successful response.
  final ApiSuccessNavigation? apiSuccessResponseNavigation;

  // ── Refresh / Retry ───────────────────────────────────────────────────────

  /// Automatically refresh on 401 using this callback, then retry once.
  final Future<String?> Function()? onUnauthorizedRefreshToken;

  /// Max retry attempts (default 0 = no retry on failure).
  final int retryCount;

  /// Delay between retries.
  final Duration retryDelay;

  // ── Lifecycle callbacks ───────────────────────────────────────────────────

  /// Called with the final [ApiResponse] on success.
  final void Function(ApiResponse response)? onSuccess;

  /// Called with the final [ApiResponse] on failure.
  final void Function(ApiResponse response)? onError;

  /// Called regardless of outcome (like a `finally` block).
  final void Function()? onComplete;

  // ── Constructor ───────────────────────────────────────────────────────────

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
  });

  // ── Main call method ──────────────────────────────────────────────────────

  /// Execute the request. Returns an [ApiResponse] — never throws.
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
      dev.log('ApiClient unexpected error: $e', stackTrace: stack);
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

    // Handle 401 token refresh
    if (response.statusCode == 401 && onUnauthorizedRefreshToken != null) {
      final newToken = await onUnauthorizedRefreshToken!();
      if (newToken != null) {
        // Rebuild with refreshed bearer token and retry once.
        final refreshed = FlutterApiCraft(
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
          enableBodyResponseDebugPrint: enableBodyResponseDebugPrint,
          enableApiSuccessResponseDebugPrint: enableApiSuccessResponseDebugPrint,
        );
        return refreshed._executeOnce();
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
    try {
      // Mutable copies for scripts to modify.
      final mutableHeaders = Map<String, String>.from(apiHeaders);
      final mutableParams = Map<String, String>.from(apiParams?.query ?? {});
      final mutableBody = <String, dynamic>{};

      if (apiBody?.rawData is Map) {
        mutableBody.addAll(Map<String, dynamic>.from(
            apiBody!.rawData as Map<String, dynamic>));
      }

      // ① Pre-request script
      if (apiScripts?.preRequest != null) {
        await apiScripts!.preRequest!(
          headers: mutableHeaders,
          params: mutableParams,
          body: mutableBody,
        );
      }

      // ② Merge script mutations back into params
      final finalParams = ApiParams(
        query: {...?apiParams?.query, ...mutableParams},
        multiQuery: apiParams?.multiQuery,
      );

      // ③ Build request
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

      // ④ Send
      final streamedResponse = await request.send().timeout(
        apiSettings.receiveTimeout,
      );
      final responseString =
      await streamedResponse.stream.bytesToString();
      final responseHeaders = streamedResponse.headers;

      // ⑤ Handle cookies from response
      CookieManager.instance.handleResponseCookies(
          request.url.host, responseHeaders, apiCookies);

      // ⑥ Parse body
      dynamic parsedBody;
      try {
        parsedBody = jsonDecode(responseString);
      } catch (_) {
        parsedBody = responseString;
      }

      // ⑦ Debug prints
      if (enableBodyResponseDebugPrint) {
        dev.log(
          '🌐 API Response [$path]\n'
              'Status: ${streamedResponse.statusCode}\n'
              'Body: $responseString',
          name: 'flutter_api_craft',
        );
      }

      // ⑧ Post-response script
      if (apiScripts?.postResponse != null) {
        await apiScripts!.postResponse!(
          statusCode: streamedResponse.statusCode,
          responseBody: parsedBody,
          headers: Map<String, String>.from(responseHeaders),
        );
      }

      // ⑨ Determine success
      final code = streamedResponse.statusCode;
      final isSuccessCode = code >= 200 && code < 300;
      bool successFlag = isSuccessCode;

      if (parsedBody is Map && parsedBody.containsKey('success')) {
        successFlag = isSuccessCode && parsedBody['success'] == true;
      }

      // ⑩ Extract error message
      String? errorMsg;
      if (!successFlag) {
        errorMsg = _extractMessage(parsedBody) ??
            'Request failed with status $code';
      }

      if (enableApiSuccessResponseDebugPrint && successFlag) {
        dev.log(
          '✅ API Success [$path] — $code',
          name: 'flutter_api_craft',
        );
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
    }
  }

  // ── Feedback (snackbars + navigation) ─────────────────────────────────────

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
          backgroundColor: cfg.successBackgroundColor ?? cfg.backgroundColor ?? Colors.green,
          colorText: cfg.textColor as Color? ?? Colors.white,
          snackPosition: cfg.position as getx.SnackPosition? ?? getx.SnackPosition.BOTTOM,
          duration: cfg.duration,
          borderRadius: cfg.borderRadius,
          margin: cfg.margin as EdgeInsets? ?? const EdgeInsets.all(12),
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
          backgroundColor: cfg.errorBackgroundColor ?? cfg.backgroundColor ?? Colors.red,
          colorText: cfg.textColor as Color? ?? Colors.white,
          snackPosition: cfg.position as getx.SnackPosition? ?? getx.SnackPosition.BOTTOM,
          duration: cfg.duration,
          borderRadius: cfg.borderRadius,
          margin: cfg.margin as EdgeInsets? ?? const EdgeInsets.all(12),
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
        break;
      case NavigationAction.popUntil:
        if (nav.routeName != null) {
          getx.Get.until((route) => route.settings.name == nav.routeName);
        }
        break;
      case NavigationAction.pushNamed:
        if (nav.routeName != null) {
          getx.Get.toNamed(nav.routeName!, arguments: nav.arguments);
        }
        break;
      case NavigationAction.pushReplacement:
        if (nav.routeName != null) {
          getx.Get.offNamed(nav.routeName!, arguments: nav.arguments);
        }
        break;
      case NavigationAction.pushAndRemoveUntil:
        if (nav.routeName != null) {
          getx.Get.offAllNamed(nav.routeName!, arguments: nav.arguments);
        }
        break;
      case NavigationAction.offAll:
        if (nav.routeName != null) {
          getx.Get.offAllNamed(nav.routeName!, arguments: nav.arguments);
        } else if (nav.widgetBuilder != null) {
          getx.Get.offAll(nav.widgetBuilder!);
        }
        break;
    }
  }

  // ── Helper: extract message from response body ────────────────────────────

  static String? _extractMessage(dynamic body) {
    if (body is Map) {
      for (final key in ['message', 'error', 'errors', 'detail', 'msg']) {
        if (body[key] != null) return body[key].toString();
      }
    }
    return null;
  }
}
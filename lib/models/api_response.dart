/// The unified response object returned by every `FlutterApiCraft.call`.
///
/// Never throws — all errors are captured and surfaced through this object.
///
/// ```dart
/// final res = await FlutterApiCraft(
///   baseUrl: 'https://api.example.com',
///   path: '/users',
/// ).call();
///
/// if (res.isSuccess) {
///   print(res['data']);        // read a key from the body Map
///   print(res.message);        // read the "message" field
/// } else {
///   print(res.errorMessage);   // human-readable error
///   print(res.statusCode);     // HTTP status code (0 = network error)
/// }
/// ```
class ApiResponse {
  /// HTTP status code.
  ///
  /// `0` means a network-level error occurred and no HTTP response was received.
  final int statusCode;

  /// Raw response body as a string.
  final String rawBody;

  /// Parsed response body.
  ///
  /// - [Map] for JSON objects.
  /// - [List] for JSON arrays.
  /// - [String] for non-JSON responses.
  /// - `null` if a network error occurred.
  final dynamic data;

  /// `true` when [statusCode] is 2xx **and** `data['success']` (if present)
  /// is `true`.
  final bool isSuccess;

  /// Human-readable error message extracted from the response body or the
  /// caught exception.
  ///
  /// `null` on success.
  final String? errorMessage;

  /// Original exception object, when a Dart exception was caught instead of
  /// receiving an HTTP response.
  final Object? exception;

  /// All response headers as a flat key/value map.
  final Map<String, String> headers;

  /// Creates an [ApiResponse].
  const ApiResponse({
    required this.statusCode,
    required this.rawBody,
    required this.data,
    required this.isSuccess,
    required this.headers,
    this.errorMessage,
    this.exception,
  });

  // ── Convenience accessors ─────────────────────────────────────────────────

  /// Read a key directly from the response [Map].
  ///
  /// Returns `null` if [data] is not a [Map] or the key does not exist.
  dynamic operator [](String key) {
    if (data is Map) return (data as Map)[key];
    return null;
  }

  /// `true` when a network or Dart exception occurred
  /// (no HTTP response was received).
  bool get isNetworkError => statusCode == 0 && exception != null;

  /// The `message` (or `msg`/`detail`) field from the response body, or `null`.
  String? get message {
    if (data is Map) {
      for (final key in ['message', 'msg', 'detail']) {
        if ((data as Map)[key] != null) {
          return (data as Map)[key].toString();
        }
      }
    }
    return null;
  }

  @override
  String toString() =>
      'ApiResponse(statusCode: $statusCode, isSuccess: $isSuccess, '
          'errorMessage: $errorMessage)';
}
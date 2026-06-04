/// The response object returned from every [ApiClient] call.
class ApiResponse<T> {
  /// HTTP status code.
  final int statusCode;

  /// Raw response body (string).
  final String rawBody;

  /// Parsed response body (Map, List, or String).
  final dynamic data;

  /// True when statusCode is 2xx and [data]['success'] (if present) is true.
  final bool isSuccess;

  /// Error message extracted from the response or caught exception.
  final String? errorMessage;

  /// Original exception, if any.
  final Object? exception;

  /// All response headers.
  final Map<String, String> headers;

  const ApiResponse({
    required this.statusCode,
    required this.rawBody,
    required this.data,
    required this.isSuccess,
    required this.headers,
    this.errorMessage,
    this.exception,
  });

  /// Convenience: read a key from the response map.
  dynamic operator [](String key) {
    if (data is Map) return (data as Map)[key];
    return null;
  }

  @override
  String toString() =>
      'ApiResponse(statusCode: $statusCode, isSuccess: $isSuccess, errorMessage: $errorMessage)';
}
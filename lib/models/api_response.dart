/// The response object returned from every [FlutterApiCraft] call.
/// Never throws — always returns a structured response.
class ApiResponse {
  /// HTTP status code. 0 means a network/exception error occurred.
  final int statusCode;

  /// Raw response body as a string.
  final String rawBody;

  /// Parsed response body — could be Map, List, or String.
  final dynamic data;

  /// True when statusCode is 2xx AND data['success'] (if present) is true.
  final bool isSuccess;

  /// Error message extracted from response body or caught exception.
  final String? errorMessage;

  /// Original exception object, if any.
  final Object? exception;

  /// All response headers as key-value pairs.
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

  /// Convenience: read a key directly from the response Map.
  /// Returns null if data is not a Map or key doesn't exist.
  dynamic operator [](String key) {
    if (data is Map) return (data as Map)[key];
    return null;
  }

  /// True if a network/exception error occurred (no HTTP response received).
  bool get isNetworkError => statusCode == 0 && exception != null;

  /// Convenience: get the message field from response body.
  String? get message {
    if (data is Map) {
      for (final key in ['message', 'msg', 'detail']) {
        if (data[key] != null) return data[key].toString();
      }
    }
    return null;
  }

  @override
  String toString() =>
      'ApiResponse(statusCode: $statusCode, isSuccess: $isSuccess, errorMessage: $errorMessage)';
}
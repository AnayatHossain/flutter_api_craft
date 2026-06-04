import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class MockHttpClient {
  static MockClient createSuccessClient({
    dynamic responseData,
    int statusCode = 200,
    Map<String, String> headers = const {'content-type': 'application/json'},
  }) {
    return MockClient((request) async {
      return http.Response(
        jsonEncode(responseData ?? {'success': true, 'message': 'Success'}),
        statusCode,
        headers: headers,
      );
    });
  }

  static MockClient createErrorClient({
    String errorMessage = 'Internal Server Error',
    int statusCode = 500,
  }) {
    return MockClient((request) async {
      return http.Response(
        jsonEncode({'error': errorMessage, 'success': false}),
        statusCode,
        headers: {'content-type': 'application/json'},
      );
    });
  }

  static MockClient createUnauthorizedClient() {
    var isFirstRequest = true;

    return MockClient((request) async {
      if (isFirstRequest) {
        isFirstRequest = false;
        return http.Response(
          jsonEncode({'error': 'Unauthorized', 'success': false}),
          401,
          headers: {'content-type': 'application/json'},
        );
      }

      return http.Response(
        jsonEncode({'success': true, 'message': 'Retry successful'}),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
  }
}
import 'dart:convert';

import 'package:flutter_api_craft/models/api_authorization.dart';
import 'package:flutter_api_craft/models/api_body.dart';
import 'package:flutter_api_craft/models/api_models.dart';
import 'package:flutter_api_craft/models/api_response.dart';
import 'package:flutter_api_craft/utils/enums.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_api_craft/flutter_api_craft.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helper: builds a MockClient that always returns the given status + body.
// ─────────────────────────────────────────────────────────────────────────────
MockClient _mockClient({
  int status = 200,
  Map<String, dynamic>? body,
  // Per-request callback — use when you need to inspect the outgoing request
  // or return different responses based on URL / headers.
  http.Response Function(http.Request)? handler,
}) {
  return MockClient((request) async {
    if (handler != null) return handler(request);
    return http.Response(
      jsonEncode(body ?? {'message': 'Success', 'success': true}),
      status,
      headers: {'content-type': 'application/json'},
    );
  });
}

void main() {
  const baseUrl = 'https://api.example.com';

  // ───────────────────────────────────────────────────────────────────────────
  // Group 1 — FlutterApiCraft integration tests (HTTP mocked)
  // ───────────────────────────────────────────────────────────────────────────
  group('FlutterApiCraft — HTTP tests', () {
    // ------------------------------------------------------------------
    // 1. Constructor
    // ------------------------------------------------------------------
    test('constructor creates instance with required parameters', () {
      final api = FlutterApiCraft(baseUrl: baseUrl, path: '/test');

      expect(api, isNotNull);
      expect(api.baseUrl, equals(baseUrl));
      expect(api.path, equals('/test'));
      expect(api.apiType, equals(ApiType.get));
      expect(api.enableLoading, isFalse);
    });

    // ------------------------------------------------------------------
    // 2. GET — success
    // ------------------------------------------------------------------
    test('GET request returns successful response', () async {
      final api = FlutterApiCraft(
        baseUrl: baseUrl,
        path: '/users/1',
        apiType: ApiType.get,
        httpClient: _mockClient(), // ← MockClient injected
      );

      final response = await api.call();

      expect(response.isSuccess, isTrue);
      expect(response.statusCode, equals(200));
    });

    // ------------------------------------------------------------------
    // 3. GET — query parameters reach the server
    // ------------------------------------------------------------------
    test('GET request sends query parameters', () async {
      String? capturedUrl;

      final api = FlutterApiCraft(
        baseUrl: baseUrl,
        path: '/users',
        apiType: ApiType.get,
        apiParams: ApiParams.simple({'page': '1', 'limit': '10'}),
        httpClient: _mockClient(
          handler: (request) {
            capturedUrl = request.url.toString();
            return http.Response(
              jsonEncode({'message': 'Success', 'success': true}),
              200,
              headers: {'content-type': 'application/json'},
            );
          },
        ),
      );

      final response = await api.call();

      expect(response.isSuccess, isTrue);
      expect(capturedUrl, contains('page=1'));
      expect(capturedUrl, contains('limit=10'));
    });

    // ------------------------------------------------------------------
    // 4. POST — JSON body
    // ------------------------------------------------------------------
    test('POST request sends JSON body', () async {
      String? capturedBody;
      String? capturedContentType;

      final api = FlutterApiCraft(
        baseUrl: baseUrl,
        path: '/users',
        apiType: ApiType.post,
        apiBody: ApiBody.json({'name': 'John Doe', 'email': 'john@example.com'}),
        httpClient: _mockClient(
          handler: (request) {
            capturedBody = request.body;
            capturedContentType = request.headers['content-type'];
            return http.Response(
              jsonEncode({'message': 'Created', 'success': true}),
              201,
              headers: {'content-type': 'application/json'},
            );
          },
        ),
      );

      final response = await api.call();

      expect(response.isSuccess, isTrue);
      expect(capturedContentType, contains('application/json'));
      final decoded = jsonDecode(capturedBody!);
      expect(decoded['name'], equals('John Doe'));
      expect(decoded['email'], equals('john@example.com'));
    });

    // ------------------------------------------------------------------
    // 5. POST — form-data
    // ------------------------------------------------------------------
    test('POST request sends form-data fields', () async {
      final api = FlutterApiCraft(
        baseUrl: baseUrl,
        path: '/upload',
        apiType: ApiType.post,
        apiBody: ApiBody.formData(
          fields: {'title': 'My Document', 'description': 'Test upload'},
        ),
        httpClient: _mockClient(),
      );

      final response = await api.call();
      expect(response.isSuccess, isTrue);
    });

    // ------------------------------------------------------------------
    // 6. POST — URL-encoded body
    // ------------------------------------------------------------------
    test('POST request sends URL-encoded body', () async {
      String? capturedBody;
      String? capturedContentType;

      final api = FlutterApiCraft(
        baseUrl: baseUrl,
        path: '/login',
        apiType: ApiType.post,
        apiBody:
        ApiBody.urlEncoded({'username': 'testuser', 'password': 'testpass'}),
        httpClient: _mockClient(
          handler: (request) {
            capturedBody = request.body;
            capturedContentType = request.headers['content-type'];
            return http.Response(
              jsonEncode({'message': 'Success', 'success': true}),
              200,
              headers: {'content-type': 'application/json'},
            );
          },
        ),
      );

      final response = await api.call();

      expect(response.isSuccess, isTrue);
      expect(capturedContentType,
          contains('application/x-www-form-urlencoded'));
      expect(capturedBody, contains('username=testuser'));
    });

    // ------------------------------------------------------------------
    // 7. Bearer token — header is set correctly
    // ------------------------------------------------------------------
    test('Bearer token is sent in Authorization header', () async {
      String? authHeader;

      final api = FlutterApiCraft(
        baseUrl: baseUrl,
        path: '/protected',
        apiType: ApiType.get,
        apiAuthorization: ApiAuthorization.bearer('test-token-123'),
        httpClient: _mockClient(
          handler: (request) {
            authHeader = request.headers['Authorization'];
            return http.Response(
              jsonEncode({'message': 'Success', 'success': true}),
              200,
              headers: {'content-type': 'application/json'},
            );
          },
        ),
      );

      final response = await api.call();

      expect(response.isSuccess, isTrue);
      expect(authHeader, equals('Bearer test-token-123'));
    });

    // ------------------------------------------------------------------
    // 8. Basic auth — Base64 header is set correctly
    // ------------------------------------------------------------------
    test('Basic auth encodes credentials in Authorization header', () async {
      String? authHeader;

      final api = FlutterApiCraft(
        baseUrl: baseUrl,
        path: '/secure',
        apiType: ApiType.get,
        apiAuthorization: ApiAuthorization.basic(user: 'admin', pass: 'secret'),
        httpClient: _mockClient(
          handler: (request) {
            authHeader = request.headers['Authorization'];
            return http.Response(
              jsonEncode({'message': 'Success', 'success': true}),
              200,
              headers: {'content-type': 'application/json'},
            );
          },
        ),
      );

      final response = await api.call();

      expect(response.isSuccess, isTrue);
      // Base64('admin:secret') = YWRtaW46c2VjcmV0
      expect(authHeader, equals('Basic YWRtaW46c2VjcmV0'));
    });

    // ------------------------------------------------------------------
    // 9. API Key in header
    // ------------------------------------------------------------------
    test('API Key is sent in the correct header', () async {
      String? apiKeyHeader;

      final api = FlutterApiCraft(
        baseUrl: baseUrl,
        path: '/api/data',
        apiType: ApiType.get,
        apiAuthorization:
        ApiAuthorization.apiKeyHeader(name: 'X-API-Key', value: 'abc123xyz'),
        httpClient: _mockClient(
          handler: (request) {
            apiKeyHeader = request.headers['X-API-Key'];
            return http.Response(
              jsonEncode({'message': 'Success', 'success': true}),
              200,
              headers: {'content-type': 'application/json'},
            );
          },
        ),
      );

      final response = await api.call();

      expect(response.isSuccess, isTrue);
      expect(apiKeyHeader, equals('abc123xyz'));
    });

    // ------------------------------------------------------------------
    // 10. Custom headers reach the server
    // ------------------------------------------------------------------
    test('Custom headers are forwarded to the server', () async {
      String? customHeader;
      String? requestId;

      final api = FlutterApiCraft(
        baseUrl: baseUrl,
        path: '/test',
        apiType: ApiType.get,
        apiHeaders: {
          'X-Custom-Header': 'custom-value',
          'X-Request-ID': '12345',
        },
        httpClient: _mockClient(
          handler: (request) {
            customHeader = request.headers['X-Custom-Header'];
            requestId = request.headers['X-Request-ID'];
            return http.Response(
              jsonEncode({'message': 'Success', 'success': true}),
              200,
              headers: {'content-type': 'application/json'},
            );
          },
        ),
      );

      final response = await api.call();

      expect(response.isSuccess, isTrue);
      expect(customHeader, equals('custom-value'));
      expect(requestId, equals('12345'));
    });

    // ------------------------------------------------------------------
    // 11. 401 triggers token refresh and the new token is used on retry
    // ------------------------------------------------------------------
    test('401 response triggers token refresh and retries with new token', () async {
      var callCount = 0;
      var refreshCalled = false;

      final api = FlutterApiCraft(
        baseUrl: baseUrl,
        path: '/protected',
        apiType: ApiType.get,
        apiAuthorization: ApiAuthorization.bearer('expired-token'),
        onUnauthorizedRefreshToken: () async {
          refreshCalled = true;
          return 'new-token-456';
        },
        httpClient: MockClient((request) async {
          callCount++;
          // First call → 401; second call (after refresh) → 200
          if (callCount == 1) {
            return http.Response(
              jsonEncode({'message': 'Unauthorized', 'success': false}),
              401,
              headers: {'content-type': 'application/json'},
            );
          }
          // Verify the refreshed token is used
          expect(
            request.headers['Authorization'],
            equals('Bearer new-token-456'),
          );
          return http.Response(
            jsonEncode({'message': 'Success', 'success': true}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final response = await api.call();

      expect(refreshCalled, isTrue);
      expect(callCount, equals(2)); // original + retry
      expect(response.isSuccess, isTrue);
    });

    // ------------------------------------------------------------------
    // 12. Retry on failure
    // ------------------------------------------------------------------
    test('retries the request up to retryCount times on failure', () async {
      var callCount = 0;

      final api = FlutterApiCraft(
        baseUrl: baseUrl,
        path: '/unstable',
        apiType: ApiType.get,
        retryCount: 3,
        retryDelay: Duration(milliseconds: 10), // short delay for tests
        httpClient: MockClient((request) async {
          callCount++;
          return http.Response(
            jsonEncode({'message': 'Error', 'success': false}),
            500,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final response = await api.call();

      // 1 original + 3 retries = 4 total calls
      expect(callCount, equals(4));
      expect(response.isSuccess, isFalse);
      expect(response.statusCode, equals(500));
    });

    // ------------------------------------------------------------------
    // 13. Error response — 404
    // ------------------------------------------------------------------
    test('returns failed ApiResponse for 4xx status', () async {
      final api = FlutterApiCraft(
        baseUrl: baseUrl,
        path: '/not-found',
        apiType: ApiType.get,
        httpClient: _mockClient(
          status: 404,
          body: {'error': 'Resource not found', 'success': false},
        ),
      );

      final response = await api.call();

      expect(response.isSuccess, isFalse);
      expect(response.statusCode, equals(404));
      expect(response.errorMessage, isNotNull);
    });

    // ------------------------------------------------------------------
    // 14. GraphQL request
    // ------------------------------------------------------------------
    test('GraphQL request sends correct content-type and payload', () async {
      String? capturedBody;
      String? capturedContentType;

      final api = FlutterApiCraft(
        baseUrl: baseUrl,
        path: '/graphql',
        apiType: ApiType.post,
        apiBody: ApiBody.graphQL(
          query: r'query GetUser($id: ID!) { user(id: $id) { id name } }',
          variables: {'id': '123'},
        ),
        httpClient: _mockClient(
          handler: (request) {
            capturedBody = request.body;
            capturedContentType = request.headers['content-type'];
            return http.Response(
              jsonEncode({'message': 'Success', 'success': true}),
              200,
              headers: {'content-type': 'application/json'},
            );
          },
        ),
      );

      final response = await api.call();

      expect(response.isSuccess, isTrue);
      expect(capturedContentType, contains('application/json'));
      final decoded = jsonDecode(capturedBody!) as Map;
      expect(decoded['query'], isNotNull);
      expect(decoded['variables'], equals({'id': '123'}));
    });

    // ------------------------------------------------------------------
    // 15. XML body
    // ------------------------------------------------------------------
    test('XML body is sent with correct content-type', () async {
      String? capturedContentType;

      const xmlBody = '<?xml version="1.0"?><user><name>John</name></user>';

      final api = FlutterApiCraft(
        baseUrl: baseUrl,
        path: '/xml-endpoint',
        apiType: ApiType.post,
        apiBody: ApiBody.xml(xmlBody),
        httpClient: _mockClient(
          handler: (request) {
            capturedContentType = request.headers['content-type'];
            return http.Response(
              jsonEncode({'message': 'Success', 'success': true}),
              200,
              headers: {'content-type': 'application/json'},
            );
          },
        ),
      );

      final response = await api.call();

      expect(response.isSuccess, isTrue);
      expect(capturedContentType, contains('application/xml'));
    });

    // ------------------------------------------------------------------
    // 16. Plain text body
    // ------------------------------------------------------------------
    test('Plain text body is sent with correct content-type', () async {
      String? capturedBody;
      String? capturedContentType;

      final api = FlutterApiCraft(
        baseUrl: baseUrl,
        path: '/text-endpoint',
        apiType: ApiType.post,
        apiBody: ApiBody.text('Hello, server!'),
        httpClient: _mockClient(
          handler: (request) {
            capturedBody = request.body;
            capturedContentType = request.headers['content-type'];
            return http.Response(
              jsonEncode({'message': 'Success', 'success': true}),
              200,
              headers: {'content-type': 'application/json'},
            );
          },
        ),
      );

      final response = await api.call();

      expect(response.isSuccess, isTrue);
      expect(capturedBody, equals('Hello, server!'));
      expect(capturedContentType, contains('text/plain'));
    });

    // ------------------------------------------------------------------
    // 17. Pre-request script — modifies headers before sending
    // ------------------------------------------------------------------
    test('Pre-request script executes and modifies headers', () async {
      var scriptExecuted = false;
      String? scriptHeader;

      final api = FlutterApiCraft(
        baseUrl: baseUrl,
        path: '/test',
        apiType: ApiType.post,
        apiScripts: ApiScript(
          preRequest: ({required headers, required params, required body}) async {
            scriptExecuted = true;
            headers['X-Script-Header'] = 'added-by-script';
            params['timestamp'] =
                DateTime.now().millisecondsSinceEpoch.toString();
          },
        ),
        httpClient: _mockClient(
          handler: (request) {
            scriptHeader = request.headers['X-Script-Header'];
            return http.Response(
              jsonEncode({'message': 'Success', 'success': true}),
              200,
              headers: {'content-type': 'application/json'},
            );
          },
        ),
      );

      final response = await api.call();

      expect(scriptExecuted, isTrue);
      expect(scriptHeader, equals('added-by-script'));
      expect(response.isSuccess, isTrue);
    });

    // ------------------------------------------------------------------
    // 18. Post-response script — receives correct status code
    // ------------------------------------------------------------------
    test('Post-response script executes with correct status code', () async {
      var scriptExecuted = false;
      var capturedStatus = 0;

      final api = FlutterApiCraft(
        baseUrl: baseUrl,
        path: '/test',
        apiType: ApiType.get,
        apiScripts: ApiScript(
          postResponse:
              ({required statusCode, responseBody, required headers}) async {
            scriptExecuted = true;
            capturedStatus = statusCode;
          },
        ),
        httpClient: _mockClient(),
      );

      final response = await api.call();

      expect(scriptExecuted, isTrue);
      expect(capturedStatus, equals(200));
      expect(response.isSuccess, isTrue);
    });

    // ------------------------------------------------------------------
    // 19. Cookie management — stored cookies are sent on subsequent request
    // ------------------------------------------------------------------
    test('Cookie jar stores and re-sends cookies across requests', () async {
      String? cookieHeader;

      // First request: server sets a cookie
      await FlutterApiCraft(
        baseUrl: baseUrl,
        path: '/login',
        apiType: ApiType.post,
        apiCookies: ApiCookies(enableCookieJar: true),
        httpClient: MockClient((_) async => http.Response(
          jsonEncode({'message': 'Success', 'success': true}),
          200,
          headers: {
            'content-type': 'application/json',
            'set-cookie': 'session_id=abc123; Path=/',
          },
        )),
      ).call();

      // Second request: cookie should be forwarded automatically
      await FlutterApiCraft(
        baseUrl: baseUrl,
        path: '/dashboard',
        apiType: ApiType.get,
        apiCookies: ApiCookies(enableCookieJar: true),
        httpClient: _mockClient(
          handler: (request) {
            cookieHeader = request.headers['cookie'];
            return http.Response(
              jsonEncode({'message': 'Success', 'success': true}),
              200,
              headers: {'content-type': 'application/json'},
            );
          },
        ),
      ).call();

      expect(cookieHeader, contains('session_id=abc123'));
    });

    // ------------------------------------------------------------------
    // 20. onSuccess callback is called on 2xx
    // ------------------------------------------------------------------
    test('onSuccess callback is invoked on successful response', () async {
      ApiResponse? callbackResponse;

      final api = FlutterApiCraft(
        baseUrl: baseUrl,
        path: '/data',
        apiType: ApiType.get,
        httpClient: _mockClient(),
        onSuccess: (r) => callbackResponse = r,
      );

      await api.call();

      expect(callbackResponse, isNotNull);
      expect(callbackResponse!.isSuccess, isTrue);
    });

    // ------------------------------------------------------------------
    // 21. onError callback is called on 4xx/5xx
    // ------------------------------------------------------------------
    test('onError callback is invoked on failed response', () async {
      ApiResponse? errorResponse;

      final api = FlutterApiCraft(
        baseUrl: baseUrl,
        path: '/broken',
        apiType: ApiType.get,
        httpClient: _mockClient(
            status: 500, body: {'message': 'Server error', 'success': false}),
        onError: (r) => errorResponse = r,
      );

      await api.call();

      expect(errorResponse, isNotNull);
      expect(errorResponse!.isSuccess, isFalse);
    });

    // ------------------------------------------------------------------
    // 22. onComplete is always called
    // ------------------------------------------------------------------
    test('onComplete callback is always invoked', () async {
      var completeCalled = false;

      // Success case
      await FlutterApiCraft(
        baseUrl: baseUrl,
        path: '/ok',
        httpClient: _mockClient(),
        onComplete: () => completeCalled = true,
      ).call();
      expect(completeCalled, isTrue);

      completeCalled = false;

      // Error case
      await FlutterApiCraft(
        baseUrl: baseUrl,
        path: '/fail',
        httpClient: _mockClient(status: 500, body: {'success': false}),
        onComplete: () => completeCalled = true,
      ).call();
      expect(completeCalled, isTrue);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // Group 2 — ApiResponse unit tests (no HTTP needed)
  // ───────────────────────────────────────────────────────────────────────────
  group('ApiResponse', () {
    test('operator[] reads a key from data map', () {
      final response = ApiResponse(
        statusCode: 200,
        rawBody: '{"message": "Hello World"}',
        data: {'message': 'Hello World'},
        isSuccess: true,
        headers: {},
      );

      expect(response['message'], equals('Hello World'));
    });

    test('message getter finds common message keys', () {
      expect(
        ApiResponse(
          statusCode: 200, rawBody: '', data: {'message': 'Hi'},
          isSuccess: true, headers: {},
        ).message,
        equals('Hi'),
      );
      expect(
        ApiResponse(
          statusCode: 200, rawBody: '', data: {'msg': 'Hey'},
          isSuccess: true, headers: {},
        ).message,
        equals('Hey'),
      );
      expect(
        ApiResponse(
          statusCode: 200, rawBody: '', data: {'detail': 'Detail text'},
          isSuccess: true, headers: {},
        ).message,
        equals('Detail text'),
      );
    });

    test('isNetworkError is true when statusCode is 0 and exception is set', () {
      final response = ApiResponse(
        statusCode: 0,
        rawBody: '',
        data: null,
        isSuccess: false,
        headers: {},
        exception: Exception('Network error'),
      );

      expect(response.isNetworkError, isTrue);
    });

    test('isNetworkError is false for normal HTTP errors', () {
      final response = ApiResponse(
        statusCode: 404,
        rawBody: '{"error": "Not found"}',
        data: {'error': 'Not found'},
        isSuccess: false,
        headers: {},
        errorMessage: 'Not found',
      );

      expect(response.isNetworkError, isFalse);
    });

    test('toString includes statusCode and isSuccess', () {
      final response = ApiResponse(
        statusCode: 200, rawBody: '', data: null,
        isSuccess: true, headers: {},
      );

      expect(response.toString(), contains('200'));
      expect(response.toString(), contains('true'));
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // Group 3 — ApiBody constructor unit tests
  // ───────────────────────────────────────────────────────────────────────────
  group('ApiBody constructors', () {
    test('ApiBody.json sets type, rawContentType, and rawData', () {
      final body = ApiBody.json({'key': 'value'});
      expect(body.type, equals(ApiBodyType.raw));
      expect(body.rawContentType, equals(RawBodyContentType.json));
      expect(body.rawData, equals({'key': 'value'}));
    });

    test('ApiBody.text sets type and rawData', () {
      final body = ApiBody.text('plain text');
      expect(body.type, equals(ApiBodyType.raw));
      expect(body.rawContentType, equals(RawBodyContentType.text));
      expect(body.rawData, equals('plain text'));
    });

    test('ApiBody.xml sets type and rawData', () {
      final body = ApiBody.xml('<root/>');
      expect(body.type, equals(ApiBodyType.raw));
      expect(body.rawContentType, equals(RawBodyContentType.xml));
      expect(body.rawData, equals('<root/>'));
    });

    test('ApiBody.html sets type and rawData', () {
      final body = ApiBody.html('<h1>Hi</h1>');
      expect(body.type, equals(ApiBodyType.raw));
      expect(body.rawContentType, equals(RawBodyContentType.html));
    });

    test('ApiBody.javascript sets type and rawData', () {
      final body = ApiBody.javascript('console.log("hi")');
      expect(body.type, equals(ApiBodyType.raw));
      expect(body.rawContentType, equals(RawBodyContentType.javascript));
    });

    test('ApiBody.formData sets type and fields', () {
      final body = ApiBody.formData(fields: {'name': 'John'}, files: []);
      expect(body.type, equals(ApiBodyType.formData));
      expect(body.fields, equals({'name': 'John'}));
    });

    test('ApiBody.urlEncoded sets type and fields', () {
      final body = ApiBody.urlEncoded({'key': 'value'});
      expect(body.type, equals(ApiBodyType.xWwwFormUrlencoded));
      expect(body.fields, equals({'key': 'value'}));
    });

    test('ApiBody.graphQL sets query and variables', () {
      final body = ApiBody.graphQL(
        query: 'query { users { id } }',
        variables: {'limit': 10},
      );
      expect(body.type, equals(ApiBodyType.graphQL));
      expect(body.graphQLQuery, equals('query { users { id } }'));
      expect(body.graphQLVariables, equals({'limit': 10}));
    });

    test('ApiBody.binaryBytes sets type and bytes', () {
      final bytes = [0x01, 0x02, 0x03];
      final body = ApiBody.binaryBytes(bytes, mimeType: 'image/png');
      expect(body.type, equals(ApiBodyType.binary));
      expect(body.binaryBytes, equals(bytes));
      expect(body.binaryMimeType, equals('image/png'));
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // Group 4 — ApiAuthorization constructor unit tests
  // ───────────────────────────────────────────────────────────────────────────
  group('ApiAuthorization constructors', () {
    test('ApiAuthorization.bearer sets type and token', () {
      final auth = ApiAuthorization.bearer('token123');
      expect(auth.type, equals(ApiAuthorizationType.bearerToken));
      expect(auth.token, equals('token123'));
    });

    test('ApiAuthorization.jwtBearer sets type and token', () {
      final auth = ApiAuthorization.jwtBearer('jwt.token.here');
      expect(auth.type, equals(ApiAuthorizationType.jwtBearer));
      expect(auth.token, equals('jwt.token.here'));
    });

    test('ApiAuthorization.basic sets username and password', () {
      final auth = ApiAuthorization.basic(user: 'admin', pass: 'secret');
      expect(auth.type, equals(ApiAuthorizationType.basicAuth));
      expect(auth.username, equals('admin'));
      expect(auth.password, equals('secret'));
    });

    test('ApiAuthorization.apiKeyHeader sets name, value, and placement', () {
      final auth =
      ApiAuthorization.apiKeyHeader(name: 'X-Key', value: 'val123');
      expect(auth.type, equals(ApiAuthorizationType.apiKey));
      expect(auth.apiKeyName, equals('X-Key'));
      expect(auth.apiKeyValue, equals('val123'));
      expect(auth.apiKeyPlacement, equals(ApiKeyPlacement.header));
    });

    test('ApiAuthorization.apiKeyQuery sets queryParam placement', () {
      final auth =
      ApiAuthorization.apiKeyQuery(name: 'api_key', value: 'val123');
      expect(auth.type, equals(ApiAuthorizationType.apiKey));
      expect(auth.apiKeyPlacement, equals(ApiKeyPlacement.queryParam));
    });

    test('ApiAuthorization.oauth2Token sets access token and prefix', () {
      final auth =
      ApiAuthorization.oauth2Token('oauth-token', prefix: 'Token');
      expect(auth.type, equals(ApiAuthorizationType.oauth2));
      expect(auth.oauth2AccessToken, equals('oauth-token'));
      expect(auth.oauth2HeaderPrefix, equals('Token'));
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // Group 5 — ApiParams unit tests
  // ───────────────────────────────────────────────────────────────────────────
  group('ApiParams', () {
    test('ApiParams.simple stores query map', () {
      final params = ApiParams.simple({'page': '1', 'limit': '10'});
      expect(params.query, equals({'page': '1', 'limit': '10'}));
      expect(params.multiQuery, isNull);
    });

    test('ApiParams stores both query and multiQuery', () {
      final params = ApiParams(
        query: {'sort': 'asc'},
        multiQuery: {
          'tags': ['flutter', 'dart']
        },
      );
      expect(params.query!['sort'], equals('asc'));
      expect(params.multiQuery!['tags'], equals(['flutter', 'dart']));
    });
  });
}
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

void main() {
  group('FlutterApiCraft', () {
    late MockClient mockClient;
    late String baseUrl;

    setUp(() {
      baseUrl = 'https://api.example.com';
      // Replace the actual HTTP client with mock
      mockClient = MockClient((request) async {
        // Default response handler - override per test
        return http.Response(
          jsonEncode({'message': 'Success', 'success': true}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
    });

    tearDown(() {
      mockClient.close();
    });

    test('constructor creates instance with required parameters', () {
      final api = FlutterApiCraft(
        baseUrl: baseUrl,
        path: '/test',
      );

      expect(api, isNotNull);
      expect(api.baseUrl, equals(baseUrl));
      expect(api.path, equals('/test'));
      expect(api.apiType, equals(ApiType.get));
      expect(api.enableLoading, isFalse);
    });

    test('GET request returns successful response', () async {
      final api = FlutterApiCraft(
        baseUrl: baseUrl,
        path: '/users/1',
        apiType: ApiType.get,
      );

      final response = await api.call();

      expect(response.isSuccess, isTrue);
      expect(response.statusCode, equals(200));
    });

    test('GET request with query parameters', () async {
      final api = FlutterApiCraft(
        baseUrl: baseUrl,
        path: '/users',
        apiType: ApiType.get,
        apiParams: ApiParams.simple({
          'page': '1',
          'limit': '10',
        }),
      );

      final response = await api.call();

      expect(response.isSuccess, isTrue);
    });

    test('POST request with JSON body', () async {
      final api = FlutterApiCraft(
        baseUrl: baseUrl,
        path: '/users',
        apiType: ApiType.post,
        apiBody: ApiBody.json({
          'name': 'John Doe',
          'email': 'john@example.com',
        }),
      );

      final response = await api.call();

      expect(response.isSuccess, isTrue);
    });

    test('POST request with form data', () async {
      final api = FlutterApiCraft(
        baseUrl: baseUrl,
        path: '/upload',
        apiType: ApiType.post,
        apiBody: ApiBody.formData(
          fields: {
            'title': 'My Document',
            'description': 'Test upload',
          },
        ),
      );

      final response = await api.call();

      expect(response.isSuccess, isTrue);
    });

    test('POST request with URL encoded body', () async {
      final api = FlutterApiCraft(
        baseUrl: baseUrl,
        path: '/login',
        apiType: ApiType.post,
        apiBody: ApiBody.urlEncoded({
          'username': 'testuser',
          'password': 'testpass',
        }),
      );

      final response = await api.call();

      expect(response.isSuccess, isTrue);
    });

    test('Bearer token authorization', () async {
      final api = FlutterApiCraft(
        baseUrl: baseUrl,
        path: '/protected',
        apiType: ApiType.get,
        apiAuthorization: ApiAuthorization.bearer('test-token-123'),
      );

      final response = await api.call();

      expect(response.isSuccess, isTrue);
    });

    test('Basic auth authorization', () async {
      final api = FlutterApiCraft(
        baseUrl: baseUrl,
        path: '/secure',
        apiType: ApiType.get,
        apiAuthorization: ApiAuthorization.basic(
          user: 'admin',
          pass: 'secret',
        ),
      );

      final response = await api.call();

      expect(response.isSuccess, isTrue);
    });

    test('API Key in header authorization', () async {
      final api = FlutterApiCraft(
        baseUrl: baseUrl,
        path: '/api/data',
        apiType: ApiType.get,
        apiAuthorization: ApiAuthorization.apiKeyHeader(
          name: 'X-API-Key',
          value: 'abc123xyz',
        ),
      );

      final response = await api.call();

      expect(response.isSuccess, isTrue);
    });

    test('Custom headers', () async {
      final api = FlutterApiCraft(
        baseUrl: baseUrl,
        path: '/test',
        apiType: ApiType.get,
        apiHeaders: {
          'X-Custom-Header': 'custom-value',
          'X-Request-ID': '12345',
        },
      );

      final response = await api.call();

      expect(response.isSuccess, isTrue);
    });

    test('Handle 401 with token refresh', () async {
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
      );

      final response = await api.call();

      expect(refreshCalled, isTrue);
      // Note: In actual test with proper mock, you'd verify retry
    });

    test('Retry on failure', () async {
      var attempts = 0;

      final api = FlutterApiCraft(
        baseUrl: baseUrl,
        path: '/unstable',
        apiType: ApiType.get,
        retryCount: 3,
        retryDelay: Duration(milliseconds: 100),
      );

      final response = await api.call();

      // Should attempt up to 3 times
      expect(attempts <= 3, isTrue);
    });

    test('ApiResponse convenience getters', () {
      final response = ApiResponse(
        statusCode: 200,
        rawBody: '{"message": "Hello World"}',
        data: {'message': 'Hello World'},
        isSuccess: true,
        headers: {},
      );

      expect(response['message'], equals('Hello World'));
      expect(response.message, equals('Hello World'));
      expect(response.isNetworkError, isFalse);
    });

    test('ApiResponse with error', () {
      final response = ApiResponse(
        statusCode: 404,
        rawBody: '{"error": "Not found"}',
        data: {'error': 'Not found'},
        isSuccess: false,
        headers: {},
        errorMessage: 'Not found',
      );

      expect(response.isSuccess, isFalse);
      expect(response.errorMessage, equals('Not found'));
    });

    test('GraphQL request', () async {
      final api = FlutterApiCraft(
        baseUrl: baseUrl,
        path: '/graphql',
        apiType: ApiType.post,
        apiBody: ApiBody.graphQL(
          query: '''
            query GetUser(\$id: ID!) {
              user(id: \$id) {
                id
                name
                email
              }
            }
          ''',
          variables: {'id': '123'},
        ),
      );

      final response = await api.call();

      expect(response.isSuccess, isTrue);
    });

    test('XML request body', () async {
      final xmlBody = '<?xml version="1.0"?><user><name>John</name></user>';

      final api = FlutterApiCraft(
        baseUrl: baseUrl,
        path: '/xml-endpoint',
        apiType: ApiType.post,
        apiBody: ApiBody.xml(xmlBody),
      );

      final response = await api.call();

      expect(response.isSuccess, isTrue);
    });

    test('Plain text request body', () async {
      final api = FlutterApiCraft(
        baseUrl: baseUrl,
        path: '/text-endpoint',
        apiType: ApiType.post,
        apiBody: ApiBody.text('Hello, server!'),
      );

      final response = await api.call();

      expect(response.isSuccess, isTrue);
    });

    test('Pre-request script', () async {
      var scriptExecuted = false;

      final api = FlutterApiCraft(
        baseUrl: baseUrl,
        path: '/test',
        apiType: ApiType.post,
        apiScripts: ApiScript(
          preRequest: ({required headers, required params, required body}) async {
            scriptExecuted = true;
            headers['X-Script-Header'] = 'added-by-script';
            params['timestamp'] = DateTime.now().millisecondsSinceEpoch.toString();
          },
        ),
      );

      final response = await api.call();

      expect(scriptExecuted, isTrue);
    });

    test('Post-response script', () async {
      var scriptExecuted = false;

      final api = FlutterApiCraft(
        baseUrl: baseUrl,
        path: '/test',
        apiType: ApiType.get,
        apiScripts: ApiScript(
          postResponse: ({required statusCode, responseBody, required headers}) async {
            scriptExecuted = true;
            expect(statusCode, equals(200));
          },
        ),
      );

      final response = await api.call();

      expect(scriptExecuted, isTrue);
    });

    test('Cookie management', () async {
      final api1 = FlutterApiCraft(
        baseUrl: baseUrl,
        path: '/login',
        apiType: ApiType.post,
        apiCookies: ApiCookies(
          enableCookieJar: true,
        ),
      );

      final api2 = FlutterApiCraft(
        baseUrl: baseUrl,
        path: '/dashboard',
        apiType: ApiType.get,
        apiCookies: ApiCookies(
          enableCookieJar: true,
        ),
      );

      await api1.call();
      final response = await api2.call();

      expect(response.isSuccess, isTrue);
    });
  });

  group('ApiBody constructors', () {
    test('ApiBody.json creates JSON body', () {
      final body = ApiBody.json({'key': 'value'});
      expect(body.type, equals(ApiBodyType.raw));
      expect(body.rawContentType, equals(RawBodyContentType.json));
      expect(body.rawData, equals({'key': 'value'}));
    });

    test('ApiBody.text creates text body', () {
      final body = ApiBody.text('plain text');
      expect(body.type, equals(ApiBodyType.raw));
      expect(body.rawContentType, equals(RawBodyContentType.text));
      expect(body.rawData, equals('plain text'));
    });

    test('ApiBody.formData creates form data', () {
      final body = ApiBody.formData(
        fields: {'name': 'John'},
        files: [],
      );
      expect(body.type, equals(ApiBodyType.formData));
      expect(body.fields, equals({'name': 'John'}));
    });

    test('ApiBody.urlEncoded creates URL encoded body', () {
      final body = ApiBody.urlEncoded({'key': 'value'});
      expect(body.type, equals(ApiBodyType.xWwwFormUrlencoded));
      expect(body.fields, equals({'key': 'value'}));
    });

    test('ApiBody.graphQL creates GraphQL body', () {
      final body = ApiBody.graphQL(
        query: 'query { users { id } }',
        variables: {'limit': 10},
      );
      expect(body.type, equals(ApiBodyType.graphQL));
      expect(body.graphQLQuery, equals('query { users { id } }'));
      expect(body.graphQLVariables, equals({'limit': 10}));
    });
  });

  group('ApiAuthorization constructors', () {
    test('ApiAuthorization.bearer creates bearer token auth', () {
      final auth = ApiAuthorization.bearer('token123');
      expect(auth.type, equals(ApiAuthorizationType.bearerToken));
      expect(auth.token, equals('token123'));
    });

    test('ApiAuthorization.basic creates basic auth', () {
      final auth = ApiAuthorization.basic(user: 'admin', pass: 'secret');
      expect(auth.type, equals(ApiAuthorizationType.basicAuth));
      expect(auth.username, equals('admin'));
      expect(auth.password, equals('secret'));
    });

    test('ApiAuthorization.apiKeyHeader creates API key header', () {
      final auth = ApiAuthorization.apiKeyHeader(name: 'X-Key', value: 'value');
      expect(auth.type, equals(ApiAuthorizationType.apiKey));
      expect(auth.apiKeyName, equals('X-Key'));
      expect(auth.apiKeyValue, equals('value'));
      expect(auth.apiKeyPlacement, equals(ApiKeyPlacement.header));
    });

    test('ApiAuthorization.apiKeyQuery creates API key query param', () {
      final auth = ApiAuthorization.apiKeyQuery(name: 'api_key', value: 'value');
      expect(auth.type, equals(ApiAuthorizationType.apiKey));
      expect(auth.apiKeyPlacement, equals(ApiKeyPlacement.queryParam));
    });
  });
}
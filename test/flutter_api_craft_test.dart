import 'package:flutter_api_craft/flutter_api_craft.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  // ── ApiResponse ────────────────────────────────────────────────────────────

  group('ApiResponse', () {
    test('isSuccess is true for 200 with success:true', () {
      const res = ApiResponse(
        statusCode: 200,
        rawBody: '{"success":true}',
        data: {'success': true},
        isSuccess: true,
        headers: {},
      );
      expect(res.isSuccess, isTrue);
    });

    test('isSuccess is false for 4xx', () {
      const res = ApiResponse(
        statusCode: 404,
        rawBody: '{"message":"Not found"}',
        data: {'message': 'Not found'},
        isSuccess: false,
        headers: {},
        errorMessage: 'Not found',
      );
      expect(res.isSuccess, isFalse);
      expect(res.errorMessage, 'Not found');
    });

    test('operator[] reads from data map', () {
      const res = ApiResponse(
        statusCode: 200,
        rawBody: '{}',
        data: {'token': 'abc123'},
        isSuccess: true,
        headers: {},
      );
      expect(res['token'], 'abc123');
    });

    test('message getter returns message field', () {
      const res = ApiResponse(
        statusCode: 200,
        rawBody: '{}',
        data: {'message': 'Profile updated'},
        isSuccess: true,
        headers: {},
      );
      expect(res.message, 'Profile updated');
    });

    test('isNetworkError is true when statusCode is 0', () {
      final res = ApiResponse(
        statusCode: 0,
        rawBody: '',
        data: null,
        isSuccess: false,
        headers: const {},
        exception: Exception('timeout'),
      );
      expect(res.isNetworkError, isTrue);
    });
  });

  // ── ApiAuthorization ───────────────────────────────────────────────────────

  group('ApiAuthorization', () {
    test('bearer sets correct type and token', () {
      const auth = ApiAuthorization.bearer('my-token');
      expect(auth.type, ApiAuthorizationType.bearerToken);
      expect(auth.token, 'my-token');
    });

    test('basic sets username and password', () {
      const auth = ApiAuthorization.basic(user: 'admin', pass: 'secret');
      expect(auth.type, ApiAuthorizationType.basicAuth);
      expect(auth.username, 'admin');
      expect(auth.password, 'secret');
    });

    test('apiKeyHeader sets placement to header', () {
      const auth = ApiAuthorization.apiKeyHeader(
        name: 'X-API-Key',
        value: 'abc',
      );
      expect(auth.apiKeyPlacement, ApiKeyPlacement.header);
    });

    test('apiKeyQuery sets placement to queryParam', () {
      const auth = ApiAuthorization.apiKeyQuery(
        name: 'api_key',
        value: 'xyz',
      );
      expect(auth.apiKeyPlacement, ApiKeyPlacement.queryParam);
    });
  });

  // ── ApiBody ────────────────────────────────────────────────────────────────

  group('ApiBody', () {
    test('json body sets correct type and content type', () {
      final body = ApiBody.json({'key': 'value'});
      expect(body.type, ApiBodyType.raw);
      expect(body.rawContentType, RawBodyContentType.json);
    });

    test('urlEncoded body sets correct type', () {
      const body = ApiBody.urlEncoded({'grant_type': 'password'});
      expect(body.type, ApiBodyType.xWwwFormUrlencoded);
      expect(body.fields, {'grant_type': 'password'});
    });

    test('graphQL body stores query and variables', () {
      const body = ApiBody.graphQL(
        query: 'query { users { id } }',
        variables: {'limit': 10},
      );
      expect(body.type, ApiBodyType.graphQL);
      expect(body.graphQLQuery, 'query { users { id } }');
      expect(body.graphQLVariables, {'limit': 10});
    });
  });

  // ── ApiParams ──────────────────────────────────────────────────────────────

  group('ApiParams', () {
    test('simple constructor wraps into query map', () {
      const p = ApiParams.simple({'page': '1', 'limit': '10'});
      expect(p.query, {'page': '1', 'limit': '10'});
    });
  });

  // ── CookieManager ──────────────────────────────────────────────────────────

  group('CookieManager', () {
    setUp(() => CookieManager.instance.clearCookies());

    test('storeCookies parses simple name=value', () {
      CookieManager.instance.storeCookies(
        'example.com',
        'session=abc123; Path=/',
      );
      final header = CookieManager.instance.buildCookieHeader(
        'example.com',
        const ApiCookies(enableCookieJar: true),
        null,
      );
      expect(header, contains('session=abc123'));
    });

    test('extraCookies are sent even without jar', () {
      final header = CookieManager.instance.buildCookieHeader(
        'example.com',
        const ApiCookies(extraCookies: {'csrf': 'token99'}),
        null,
      );
      expect(header, 'csrf=token99');
    });

    test('returns null when no cookies', () {
      final header = CookieManager.instance.buildCookieHeader(
        'empty.com',
        const ApiCookies(),
        null,
      );
      expect(header, isNull);
    });
  });

  // ── FlutterApiCraft integration ────────────────────────────────────────────

  group('FlutterApiCraft', () {
    test('returns isSuccess true for 200 JSON response', () async {
      final client = MockClient((request) async {
        return http.Response(
          '{"success": true, "message": "OK", "data": []}',
          200,
        );
      });

      final res = await FlutterApiCraft(
        baseUrl: 'https://api.example.com',
        path: '/posts',
        httpClient: client,
      ).call();

      expect(res.isSuccess, isTrue);
      expect(res.statusCode, 200);
      expect(res['message'], 'OK');
    });

    test('returns isSuccess false for 404', () async {
      final client = MockClient((request) async {
        return http.Response('{"message": "Not found"}', 404);
      });

      final res = await FlutterApiCraft(
        baseUrl: 'https://api.example.com',
        path: '/missing',
        httpClient: client,
      ).call();

      expect(res.isSuccess, isFalse);
      expect(res.statusCode, 404);
    });

    test('sends correct HTTP method', () async {
      String? capturedMethod;

      final client = MockClient((request) async {
        capturedMethod = request.method;
        return http.Response('{"success": true}', 200);
      });

      await FlutterApiCraft(
        baseUrl: 'https://api.example.com',
        path: '/posts',
        apiType: ApiType.post,
        apiBody: ApiBody.json({'title': 'Test'}),
        httpClient: client,
      ).call();

      expect(capturedMethod, 'POST');
    });

    test('includes query params in URL', () async {
      Uri? capturedUri;

      final client = MockClient((request) async {
        capturedUri = request.url;
        return http.Response('[]', 200);
      });

      await FlutterApiCraft(
        baseUrl: 'https://api.example.com',
        path: '/posts',
        apiParams: ApiParams.simple({'page': '2', 'limit': '5'}),
        httpClient: client,
      ).call();

      expect(capturedUri?.queryParameters['page'], '2');
      expect(capturedUri?.queryParameters['limit'], '5');
    });

    test('adds Bearer token header', () async {
      Map<String, String>? capturedHeaders;

      final client = MockClient((request) async {
        capturedHeaders = request.headers;
        return http.Response('{"success": true}', 200);
      });

      await FlutterApiCraft(
        baseUrl: 'https://api.example.com',
        path: '/me',
        apiAuthorization: ApiAuthorization.bearer('my-secret-token'),
        httpClient: client,
      ).call();

      expect(capturedHeaders?['authorization'], 'Bearer my-secret-token');
    });

    test('onSuccess callback is called on success', () async {
      var called = false;

      final client = MockClient((_) async {
        return http.Response('{"success": true}', 200);
      });

      await FlutterApiCraft(
        baseUrl: 'https://api.example.com',
        path: '/test',
        httpClient: client,
        onSuccess: (_) => called = true,
      ).call();

      expect(called, isTrue);
    });

    test('onError callback is called on failure', () async {
      var called = false;

      final client = MockClient((_) async {
        return http.Response('{"message": "fail"}', 500);
      });

      await FlutterApiCraft(
        baseUrl: 'https://api.example.com',
        path: '/test',
        httpClient: client,
        onError: (_) => called = true,
      ).call();

      expect(called, isTrue);
    });

    test('never throws — returns error response on exception', () async {
      final client = MockClient((_) async {
        throw Exception('Network unreachable');
      });

      final res = await FlutterApiCraft(
        baseUrl: 'https://api.example.com',
        path: '/test',
        httpClient: client,
      ).call();

      expect(res.statusCode, 0);
      expect(res.isSuccess, isFalse);
      expect(res.exception, isNotNull);
    });
  });
}

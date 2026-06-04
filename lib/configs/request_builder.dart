import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/api_authorization.dart';
import '../models/api_body.dart';
import '../models/api_models.dart';
import '../interceptors/authorization_builder.dart';
import '../interceptors/cookie_manager.dart';
import '../utils/enums.dart';

/// Assembles an [http.BaseRequest] from all the configuration objects.
class RequestBuilder {
  const RequestBuilder._();

  static Future<http.BaseRequest> build({
    required String baseUrl,
    required String path,
    required ApiType method,
    required Map<String, String> headers,
    ApiBody? body,
    ApiParams? params,
    ApiAuthorization? authorization,
    ApiCookies? cookies,
  }) async {
    // 1️⃣  Build URL + query params
    final uri = _buildUri(baseUrl, path, params, authorization);

    // 2️⃣  Merge headers
    final mergedHeaders = <String, String>{
      ...headers,
      ...AuthorizationBuilder.buildHeaders(authorization),
    };

    // 3️⃣  Cookie header
    final domain = uri.host;
    final cookieHeader = CookieManager.instance.buildCookieHeader(
        domain, cookies, cookies?.extraCookies);
    if (cookieHeader != null) mergedHeaders['cookie'] = cookieHeader;

    // 4️⃣  Build request based on body type
    if (body != null && body.type == ApiBodyType.formData) {
      return _buildMultipart(uri, method, mergedHeaders, body);
    }

    final request = http.Request(_methodString(method), uri);
    request.headers.addAll(mergedHeaders);
    _applyBody(request, body);
    return request;
  }

  // ── URI builder ───────────────────────────────────────────────────────────

  static Uri _buildUri(
      String baseUrl, String path, ApiParams? params, ApiAuthorization? auth) {
    final rawUrl = path.startsWith('http')
        ? path
        : '${baseUrl.trimRight()}/${path.trimLeft()}';

    final authQueryParams = AuthorizationBuilder.buildQueryParams(auth);

    final allQuery = <String, String>{
      ...?params?.query,
      ...authQueryParams,
    };

    final multiQuery = params?.multiQuery ?? {};

    Uri uri = Uri.parse(rawUrl);

    if (allQuery.isNotEmpty || multiQuery.isNotEmpty) {
      final queryParts = <String>[];
      uri.queryParameters.forEach(
              (k, v) => queryParts.add('${Uri.encodeQueryComponent(k)}=${Uri.encodeQueryComponent(v)}'));
      allQuery.forEach(
              (k, v) => queryParts.add('${Uri.encodeQueryComponent(k)}=${Uri.encodeQueryComponent(v)}'));
      multiQuery.forEach((k, vals) {
        for (final v in vals) {
          queryParts.add(
              '${Uri.encodeQueryComponent(k)}=${Uri.encodeQueryComponent(v)}');
        }
      });
      uri = uri.replace(query: queryParts.join('&'));
    }

    return uri;
  }

  // ── Body applicator (for non-multipart requests) ──────────────────────────

  static void _applyBody(http.Request request, ApiBody? body) {
    if (body == null || body.type == ApiBodyType.none) return;

    switch (body.type) {
      case ApiBodyType.raw:
        _applyRawBody(request, body);
        break;

      case ApiBodyType.xWwwFormUrlencoded:
        request.headers['content-type'] = 'application/x-www-form-urlencoded';
        if (body.fields != null) {
          request.bodyFields = body.fields!;
        }
        break;

      case ApiBodyType.graphQL:
        request.headers['content-type'] = 'application/json';
        final payload = <String, dynamic>{'query': body.graphQLQuery ?? ''};
        if (body.graphQLVariables != null) {
          payload['variables'] = body.graphQLVariables;
        }
        request.body = jsonEncode(payload);
        break;

      case ApiBodyType.binary:
        request.headers['content-type'] =
            body.binaryMimeType ?? 'application/octet-stream';
        if (body.binaryBytes != null) {
          request.bodyBytes = body.binaryBytes!;
        }
        break;

      default:
        break;
    }
  }

  static void _applyRawBody(http.Request request, ApiBody body) {
    switch (body.rawContentType) {
      case RawBodyContentType.json:
        request.headers['content-type'] = 'application/json';
        if (body.rawData is String) {
          request.body = body.rawData as String;
        } else {
          request.body = jsonEncode(body.rawData);
        }
        break;
      case RawBodyContentType.text:
        request.headers['content-type'] = 'text/plain';
        request.body = body.rawData?.toString() ?? '';
        break;
      case RawBodyContentType.xml:
        request.headers['content-type'] = 'application/xml';
        request.body = body.rawData?.toString() ?? '';
        break;
      case RawBodyContentType.html:
        request.headers['content-type'] = 'text/html';
        request.body = body.rawData?.toString() ?? '';
        break;
      case RawBodyContentType.javascript:
        request.headers['content-type'] = 'application/javascript';
        request.body = body.rawData?.toString() ?? '';
        break;
    }
  }

  // ── Multipart builder ─────────────────────────────────────────────────────

  static Future<http.MultipartRequest> _buildMultipart(
      Uri uri,
      ApiType method,
      Map<String, String> headers,
      ApiBody body,
      ) async {
    final request = http.MultipartRequest(_methodString(method), uri);
    request.headers.addAll(headers);

    if (body.fields != null) {
      request.fields.addAll(body.fields!);
    }

    if (body.files != null) {
      for (final apiFile in body.files!) {
        if (apiFile.file != null) {
          request.files.add(await http.MultipartFile.fromPath(
            apiFile.fieldName,
            apiFile.file!.path,
            filename: apiFile.filename,
          ));
        } else if (apiFile.bytes != null) {
          request.files.add(http.MultipartFile.fromBytes(
            apiFile.fieldName,
            apiFile.bytes!,
            filename: apiFile.filename,
          ));
        }
      }
    }

    return request;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String _methodString(ApiType method) {
    switch (method) {
      case ApiType.get:
        return 'GET';
      case ApiType.post:
        return 'POST';
      case ApiType.put:
        return 'PUT';
      case ApiType.patch:
        return 'PATCH';
      case ApiType.delete:
        return 'DELETE';
      case ApiType.head:
        return 'HEAD';
      case ApiType.options:
        return 'OPTIONS';
    }
  }
}
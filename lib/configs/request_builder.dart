import 'dart:convert';

import 'package:http/http.dart' as http;

import '../interceptors/authorization_builder.dart';
import '../interceptors/cookie_manager.dart';
import '../models/api_authorization.dart';
import '../models/api_body.dart';
import '../models/api_models.dart';
import '../utils/enums.dart';

/// Assembles an [http.BaseRequest] from all the [FlutterApiCraft] configuration
/// objects.
///
/// This class is used internally and is not intended to be called directly
/// by package consumers.
class RequestBuilder {
  const RequestBuilder._();

  /// Builds and returns the correct [http.BaseRequest] subtype:
  ///
  /// - [http.MultipartRequest] when [body.type] is [ApiBodyType.formData].
  /// - [http.Request] for all other cases.
  ///
  /// Also merges [headers], authorization headers, and the cookie header.
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
    final uri = _buildUri(baseUrl, path, params, authorization);

    final mergedHeaders = <String, String>{
      ...headers,
      ...AuthorizationBuilder.buildHeaders(authorization),
    };

    final cookieHeader = CookieManager.instance.buildCookieHeader(
      uri.host,
      cookies,
      cookies?.extraCookies,
    );
    if (cookieHeader != null) mergedHeaders['cookie'] = cookieHeader;

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
    String baseUrl,
    String path,
    ApiParams? params,
    ApiAuthorization? auth,
  ) {
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
      uri.queryParameters.forEach((k, v) {
        queryParts.add(
          '${Uri.encodeQueryComponent(k)}=${Uri.encodeQueryComponent(v)}',
        );
      });
      allQuery.forEach((k, v) {
        queryParts.add(
          '${Uri.encodeQueryComponent(k)}=${Uri.encodeQueryComponent(v)}',
        );
      });
      multiQuery.forEach((k, vals) {
        for (final v in vals) {
          queryParts.add(
            '${Uri.encodeQueryComponent(k)}=${Uri.encodeQueryComponent(v)}',
          );
        }
      });
      uri = uri.replace(query: queryParts.join('&'));
    }

    return uri;
  }

  // ── Body applicator ───────────────────────────────────────────────────────

  static void _applyBody(http.Request request, ApiBody? body) {
    if (body == null || body.type == ApiBodyType.none) return;

    switch (body.type) {
      case ApiBodyType.raw:
        _applyRawBody(request, body);
      case ApiBodyType.xWwwFormUrlencoded:
        request.headers['content-type'] = 'application/x-www-form-urlencoded';
        if (body.fields != null) request.bodyFields = body.fields!;
      case ApiBodyType.graphQL:
        request.headers['content-type'] = 'application/json';
        final payload = <String, dynamic>{'query': body.graphQLQuery ?? ''};
        if (body.graphQLVariables != null) {
          payload['variables'] = body.graphQLVariables;
        }
        request.body = jsonEncode(payload);
      case ApiBodyType.binary:
        request.headers['content-type'] =
            body.binaryMimeType ?? 'application/octet-stream';
        if (body.binaryBytes != null) request.bodyBytes = body.binaryBytes!;
      default:
        break;
    }
  }

  static void _applyRawBody(http.Request request, ApiBody body) {
    switch (body.rawContentType) {
      case RawBodyContentType.json:
        request.headers['content-type'] = 'application/json';
        request.body = body.rawData is String
            ? body.rawData as String
            : jsonEncode(body.rawData);
      case RawBodyContentType.text:
        request.headers['content-type'] = 'text/plain';
        request.body = body.rawData?.toString() ?? '';
      case RawBodyContentType.xml:
        request.headers['content-type'] = 'application/xml';
        request.body = body.rawData?.toString() ?? '';
      case RawBodyContentType.html:
        request.headers['content-type'] = 'text/html';
        request.body = body.rawData?.toString() ?? '';
      case RawBodyContentType.javascript:
        request.headers['content-type'] = 'application/javascript';
        request.body = body.rawData?.toString() ?? '';
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

    if (body.fields != null) request.fields.addAll(body.fields!);

    if (body.files != null) {
      for (final apiFile in body.files!) {
        if (apiFile.file != null) {
          request.files.add(
            await http.MultipartFile.fromPath(
              apiFile.fieldName,
              apiFile.file!.path,
              filename: apiFile.filename,
            ),
          );
        } else if (apiFile.bytes != null) {
          request.files.add(
            http.MultipartFile.fromBytes(
              apiFile.fieldName,
              apiFile.bytes!,
              filename: apiFile.filename,
            ),
          );
        }
      }
    }

    return request;
  }

  // ── Helper ────────────────────────────────────────────────────────────────

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

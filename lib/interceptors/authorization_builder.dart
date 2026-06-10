import 'dart:convert';

import '../models/api_authorization.dart';
import '../utils/enums.dart';

/// Converts an [ApiAuthorization] config into HTTP header entries and/or
/// URL query-parameter additions.
///
/// This class is used internally by [RequestBuilder] and is not intended to
/// be used directly by package consumers.
class AuthorizationBuilder {
  const AuthorizationBuilder._();

  /// Returns the HTTP headers derived from [auth].
  ///
  /// Returns an empty map when [auth] is `null` or
  /// [ApiAuthorizationType.none].
  static Map<String, String> buildHeaders(ApiAuthorization? auth) {
    if (auth == null) return {};

    switch (auth.type) {
      case ApiAuthorizationType.none:
      case ApiAuthorizationType.inheritFromParent:
        return {};

      case ApiAuthorizationType.bearerToken:
      case ApiAuthorizationType.jwtBearer:
        if (auth.token == null) return {};
        return {'Authorization': 'Bearer ${auth.token}'};

      case ApiAuthorizationType.basicAuth:
        if (auth.username == null || auth.password == null) return {};
        final encoded =
            base64.encode(utf8.encode('${auth.username}:${auth.password}'));
        return {'Authorization': 'Basic $encoded'};

      case ApiAuthorizationType.digestAuth:
        if (auth.username == null || auth.password == null) return {};
        // Full Digest requires a server challenge round-trip.
        // Expose credentials so the caller can implement the nonce exchange.
        return {
          'X-Digest-Username': auth.username!,
          'X-Digest-Password': auth.password!,
        };

      case ApiAuthorizationType.oauth1:
        // Full OAuth 1.0 HMAC signing is out of scope.
        // The caller should build the Authorization header externally and
        // pass it via apiHeaders.
        return {};

      case ApiAuthorizationType.oauth2:
        if (auth.oauth2AccessToken == null) return {};
        final prefix = auth.oauth2HeaderPrefix ?? 'Bearer';
        return {'Authorization': '$prefix ${auth.oauth2AccessToken}'};

      case ApiAuthorizationType.hawkAuthentication:
        // Hawk requires timestamp + nonce generation.
        // Build the Authorization header externally and pass it via apiHeaders.
        return {};

      case ApiAuthorizationType.awsSignature:
        // AWS SigV4 requires request canonicalization.
        // Use package:aws_signature_v4 externally for full support.
        return {};

      case ApiAuthorizationType.ntlmAuthentication:
        // NTLM requires a multi-round challenge/response handshake.
        return {};

      case ApiAuthorizationType.apiKey:
        if (auth.apiKeyName == null ||
            auth.apiKeyValue == null ||
            auth.apiKeyPlacement != ApiKeyPlacement.header) {
          return {};
        }
        return {auth.apiKeyName!: auth.apiKeyValue!};

      case ApiAuthorizationType.akamaiEdgeGrid:
        // Akamai EdgeGrid signing is proprietary.
        return {};
    }
  }

  /// Returns URL query parameters derived from [auth].
  ///
  /// Currently only handles [ApiAuthorizationType.apiKey] with
  /// [ApiKeyPlacement.queryParam].
  static Map<String, String> buildQueryParams(ApiAuthorization? auth) {
    if (auth == null) return {};
    if (auth.type == ApiAuthorizationType.apiKey &&
        auth.apiKeyPlacement == ApiKeyPlacement.queryParam &&
        auth.apiKeyName != null &&
        auth.apiKeyValue != null) {
      return {auth.apiKeyName!: auth.apiKeyValue!};
    }
    return {};
  }
}

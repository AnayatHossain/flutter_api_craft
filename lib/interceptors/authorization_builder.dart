import 'dart:convert';
import '../models/api_authorization.dart';
import '../utils/enums.dart';

/// Converts an [ApiAuthorization] config into HTTP header entries and/or
/// URL query-parameter additions.
class AuthorizationBuilder {
  const AuthorizationBuilder._();

  /// Returns additional headers to inject into the request.
  static Map<String, String> buildHeaders(ApiAuthorization? auth) {
    if (auth == null) return {};

    switch (auth.type) {
      case ApiAuthorizationType.none:
      case ApiAuthorizationType.inheritFromParent:
        return {};

      case ApiAuthorizationType.bearerToken:
        if (auth.token == null) return {};
        return {'Authorization': 'Bearer ${auth.token}'};

      case ApiAuthorizationType.jwtBearer:
        if (auth.token == null) return {};
        return {'Authorization': 'Bearer ${auth.token}'};

      case ApiAuthorizationType.basicAuth:
        if (auth.username == null || auth.password == null) return {};
        final encoded =
        base64.encode(utf8.encode('${auth.username}:${auth.password}'));
        return {'Authorization': 'Basic $encoded'};

      case ApiAuthorizationType.digestAuth:
      // Digest requires a challenge/response round-trip; for simple cases we
      // can expose the raw credentials so the caller handles the nonce.
        if (auth.username == null || auth.password == null) return {};
        return {
          'X-Digest-Username': auth.username!,
          'X-Digest-Password': auth.password!,
        };

      case ApiAuthorizationType.oauth1:
      // A full OAuth 1.0 implementation is out of scope here; we expose
      // the key fields so the user can wire in their own signer.
        return {};

      case ApiAuthorizationType.oauth2:
        if (auth.oauth2AccessToken == null) return {};
        final prefix = auth.oauth2HeaderPrefix ?? 'Bearer';
        return {'Authorization': '$prefix ${auth.oauth2AccessToken}'};

      case ApiAuthorizationType.hawkAuthentication:
      // Hawk requires timestamp + nonce; simplified stub.
        return {};

      case ApiAuthorizationType.awsSignature:
      // AWS SigV4 is complex; placeholder.
        return {};

      case ApiAuthorizationType.ntlmAuthentication:
      // NTLM requires multi-round handshake; placeholder.
        return {};

      case ApiAuthorizationType.apiKey:
        if (auth.apiKeyName == null ||
            auth.apiKeyValue == null ||
            auth.apiKeyPlacement != ApiKeyPlacement.header) return {};
        return {auth.apiKeyName!: auth.apiKeyValue!};

      case ApiAuthorizationType.akamaiEdgeGrid:
        return {};
    }
  }

  /// Returns additional query parameters to append to the URL.
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
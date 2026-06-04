import '../utils/enums.dart';

/// Holds all authorization configuration.
/// Mirrors every Postman auth type.
///
/// Usage examples:
/// ```dart
/// // Bearer token
/// ApiAuthorization.bearer('my-token')
///
/// // Basic auth
/// ApiAuthorization.basic(user: 'admin', pass: 'secret')
///
/// // API Key in header
/// ApiAuthorization.apiKeyHeader(name: 'X-API-Key', value: 'abc123')
///
/// // API Key in query param
/// ApiAuthorization.apiKeyQuery(name: 'api_key', value: 'abc123')
///
/// // OAuth2
/// ApiAuthorization(
///   type: ApiAuthorizationType.oauth2,
///   oauth2AccessToken: 'token',
///   oauth2HeaderPrefix: 'Bearer',
/// )
/// ```
class ApiAuthorization {
  final ApiAuthorizationType type;

  // ── Bearer / JWT ──────────────────────────────────────────────────────────
  final String? token;
  final String? jwtSecret;
  final String? jwtAlgorithm; // e.g. "HS256"
  final Map<String, dynamic>? jwtPayload;

  // ── Basic Auth ────────────────────────────────────────────────────────────
  final String? username;
  final String? password;

  // ── Digest Auth ───────────────────────────────────────────────────────────
  final String? realm;

  // ── OAuth 1.0 ─────────────────────────────────────────────────────────────
  final String? consumerKey;
  final String? consumerSecret;
  final String? accessToken;
  final String? tokenSecret;
  final String? signatureMethod; // "HMAC-SHA1", "RSA-SHA1", "PLAINTEXT"

  // ── OAuth 2.0 ─────────────────────────────────────────────────────────────
  final String? oauth2AccessToken;
  final String? oauth2HeaderPrefix; // default "Bearer"
  final String? oauth2TokenUrl;
  final String? oauth2ClientId;
  final String? oauth2ClientSecret;
  final String? oauth2Scope;

  // ── API Key ───────────────────────────────────────────────────────────────
  final String? apiKeyName;
  final String? apiKeyValue;
  final ApiKeyPlacement? apiKeyPlacement;

  // ── AWS Signature ─────────────────────────────────────────────────────────
  final String? awsAccessKey;
  final String? awsSecretKey;
  final String? awsRegion;
  final String? awsService;

  // ── Hawk Authentication ───────────────────────────────────────────────────
  final String? hawkId;
  final String? hawkKey;
  final String? hawkAlgorithm;

  // ── NTLM Authentication ───────────────────────────────────────────────────
  final String? ntlmUsername;
  final String? ntlmPassword;
  final String? ntlmDomain;
  final String? ntlmWorkstation;

  const ApiAuthorization({
    this.type = ApiAuthorizationType.none,
    this.token,
    this.jwtSecret,
    this.jwtAlgorithm,
    this.jwtPayload,
    this.username,
    this.password,
    this.realm,
    this.consumerKey,
    this.consumerSecret,
    this.accessToken,
    this.tokenSecret,
    this.signatureMethod,
    this.oauth2AccessToken,
    this.oauth2HeaderPrefix,
    this.oauth2TokenUrl,
    this.oauth2ClientId,
    this.oauth2ClientSecret,
    this.oauth2Scope,
    this.apiKeyName,
    this.apiKeyValue,
    this.apiKeyPlacement,
    this.awsAccessKey,
    this.awsSecretKey,
    this.awsRegion,
    this.awsService,
    this.hawkId,
    this.hawkKey,
    this.hawkAlgorithm,
    this.ntlmUsername,
    this.ntlmPassword,
    this.ntlmDomain,
    this.ntlmWorkstation,
  });

  // ── Quick constructors ────────────────────────────────────────────────────

  /// Bearer token authorization.
  const ApiAuthorization.bearer(String bearerToken)
      : this(type: ApiAuthorizationType.bearerToken, token: bearerToken);

  /// JWT Bearer token authorization.
  const ApiAuthorization.jwtBearer(String jwtToken)
      : this(type: ApiAuthorizationType.jwtBearer, token: jwtToken);

  /// HTTP Basic Auth (Base64 encodes username:password automatically).
  const ApiAuthorization.basic({
    required String user,
    required String pass,
  }) : this(
    type: ApiAuthorizationType.basicAuth,
    username: user,
    password: pass,
  );

  /// API Key sent as a request header.
  const ApiAuthorization.apiKeyHeader({
    required String name,
    required String value,
  }) : this(
    type: ApiAuthorizationType.apiKey,
    apiKeyName: name,
    apiKeyValue: value,
    apiKeyPlacement: ApiKeyPlacement.header,
  );

  /// API Key appended as a query parameter.
  const ApiAuthorization.apiKeyQuery({
    required String name,
    required String value,
  }) : this(
    type: ApiAuthorizationType.apiKey,
    apiKeyName: name,
    apiKeyValue: value,
    apiKeyPlacement: ApiKeyPlacement.queryParam,
  );

  /// OAuth 2.0 with an existing access token.
  const ApiAuthorization.oauth2Token(
      String accessToken, {
        String prefix = 'Bearer',
      }) : this(
    type: ApiAuthorizationType.oauth2,
    oauth2AccessToken: accessToken,
    oauth2HeaderPrefix: prefix,
  );
}
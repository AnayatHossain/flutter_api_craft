import '../utils/enums.dart';

/// Holds all authorization configuration for an API request.
///
/// Mirrors every auth type available in Postman's Authorization tab.
///
/// ## Quick constructors
///
/// ```dart
/// // Bearer token (most common)
/// ApiAuthorization.bearer('eyJhbGci...')
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
/// // OAuth 2.0 with existing token
/// ApiAuthorization.oauth2Token('my-access-token')
///
/// // JWT Bearer
/// ApiAuthorization.jwtBearer('eyJhbGci...')
/// ```
class ApiAuthorization {
  /// The authorization type to use.
  final ApiAuthorizationType type;

  /// Token string for [ApiAuthorizationType.bearerToken] and
  /// [ApiAuthorizationType.jwtBearer].
  final String? token;

  /// JWT signing secret (informational — signing is handled externally).
  final String? jwtSecret;

  /// JWT signing algorithm, e.g. `"HS256"` or `"RS256"`.
  final String? jwtAlgorithm;

  /// Additional JWT payload claims.
  final Map<String, dynamic>? jwtPayload;

  /// Username for [ApiAuthorizationType.basicAuth] and
  /// [ApiAuthorizationType.digestAuth].
  final String? username;

  /// Password for [ApiAuthorizationType.basicAuth] and
  /// [ApiAuthorizationType.digestAuth].
  final String? password;

  /// Digest auth realm (used in the challenge header).
  final String? realm;

  /// OAuth 1.0 consumer key.
  final String? consumerKey;

  /// OAuth 1.0 consumer secret.
  final String? consumerSecret;

  /// OAuth 1.0 access token.
  final String? accessToken;

  /// OAuth 1.0 token secret.
  final String? tokenSecret;

  /// OAuth 1.0 signature method: `"HMAC-SHA1"`, `"RSA-SHA1"`, or `"PLAINTEXT"`.
  final String? signatureMethod;

  /// OAuth 2.0 access token sent in the Authorization header.
  final String? oauth2AccessToken;

  /// Prefix for the OAuth 2.0 header. Defaults to `"Bearer"`.
  final String? oauth2HeaderPrefix;

  /// OAuth 2.0 token endpoint URL (for client-credentials flows).
  final String? oauth2TokenUrl;

  /// OAuth 2.0 client ID.
  final String? oauth2ClientId;

  /// OAuth 2.0 client secret.
  final String? oauth2ClientSecret;

  /// OAuth 2.0 requested scope.
  final String? oauth2Scope;

  /// The header or query-parameter name for an API key.
  final String? apiKeyName;

  /// The API key value.
  final String? apiKeyValue;

  /// Whether the API key goes in a header or query param.
  final ApiKeyPlacement? apiKeyPlacement;

  /// AWS IAM access key ID.
  final String? awsAccessKey;

  /// AWS IAM secret access key.
  final String? awsSecretKey;

  /// AWS region, e.g. `"us-east-1"`.
  final String? awsRegion;

  /// AWS service name, e.g. `"execute-api"`.
  final String? awsService;

  /// Hawk auth ID.
  final String? hawkId;

  /// Hawk auth key.
  final String? hawkKey;

  /// Hawk algorithm, e.g. `"sha256"`.
  final String? hawkAlgorithm;

  /// NTLM username.
  final String? ntlmUsername;

  /// NTLM password.
  final String? ntlmPassword;

  /// NTLM domain.
  final String? ntlmDomain;

  /// NTLM workstation name.
  final String? ntlmWorkstation;

  /// Creates an [ApiAuthorization] with full control over every field.
  ///
  /// Prefer the named constructors (e.g. [ApiAuthorization.bearer]) for the
  /// common cases.
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

  /// Sends `Authorization: Bearer <bearerToken>`.
  const ApiAuthorization.bearer(String bearerToken)
      : this(type: ApiAuthorizationType.bearerToken, token: bearerToken);

  /// Sends `Authorization: Bearer <jwtToken>`.
  const ApiAuthorization.jwtBearer(String jwtToken)
      : this(type: ApiAuthorizationType.jwtBearer, token: jwtToken);

  /// Sends `Authorization: Basic <base64(user:pass)>`.
  const ApiAuthorization.basic({required String user, required String pass})
      : this(
          type: ApiAuthorizationType.basicAuth,
          username: user,
          password: pass,
        );

  /// Injects the API key as the named request header.
  const ApiAuthorization.apiKeyHeader({
    required String name,
    required String value,
  }) : this(
          type: ApiAuthorizationType.apiKey,
          apiKeyName: name,
          apiKeyValue: value,
          apiKeyPlacement: ApiKeyPlacement.header,
        );

  /// Appends the API key as a URL query parameter.
  const ApiAuthorization.apiKeyQuery({
    required String name,
    required String value,
  }) : this(
          type: ApiAuthorizationType.apiKey,
          apiKeyName: name,
          apiKeyValue: value,
          apiKeyPlacement: ApiKeyPlacement.queryParam,
        );

  /// Sends `Authorization: <prefix> <accessToken>`.
  ///
  /// [prefix] defaults to `"Bearer"`.
  const ApiAuthorization.oauth2Token(
    String accessToken, {
    String prefix = 'Bearer',
  }) : this(
          type: ApiAuthorizationType.oauth2,
          oauth2AccessToken: accessToken,
          oauth2HeaderPrefix: prefix,
        );
}

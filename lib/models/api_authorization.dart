import '../utils/enums.dart';


/// Holds all authorization configuration — mirrors every Postman auth type.
class ApiAuthorization {
  final ApiAuthorizationType type;

  // Bearer / JWT
  final String? token;
  final String? jwtSecret;
  final String? jwtAlgorithm; // e.g. "HS256"
  final Map<String, dynamic>? jwtPayload;

  // Basic Auth
  final String? username;
  final String? password;

  // Digest Auth
  final String? realm;

  // OAuth 1.0
  final String? consumerKey;
  final String? consumerSecret;
  final String? accessToken;
  final String? tokenSecret;
  final String? signatureMethod; // "HMAC-SHA1", "RSA-SHA1", "PLAINTEXT"

  // OAuth 2.0
  final String? oauth2AccessToken;
  final String? oauth2HeaderPrefix; // default "Bearer"

  // API Key
  final String? apiKeyName;
  final String? apiKeyValue;
  final ApiKeyPlacement? apiKeyPlacement;

  // AWS Signature
  final String? awsAccessKey;
  final String? awsSecretKey;
  final String? awsRegion;
  final String? awsService;

  // Hawk
  final String? hawkId;
  final String? hawkKey;
  final String? hawkAlgorithm;

  // NTLM
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

  /// Quick constructor: Bearer token
  const ApiAuthorization.bearer(String bearerToken)
      : this(type: ApiAuthorizationType.bearerToken, token: bearerToken);

  /// Quick constructor: Basic auth
  const ApiAuthorization.basic({
    required String user,
    required String pass,
  }) : this(
    type: ApiAuthorizationType.basicAuth,
    username: user,
    password: pass,
  );

  /// Quick constructor: API Key in header
  const ApiAuthorization.apiKeyHeader({
    required String name,
    required String value,
  }) : this(
    type: ApiAuthorizationType.apiKey,
    apiKeyName: name,
    apiKeyValue: value,
    apiKeyPlacement: ApiKeyPlacement.header,
  );

  /// Quick constructor: API Key in query param
  const ApiAuthorization.apiKeyQuery({
    required String name,
    required String value,
  }) : this(
    type: ApiAuthorizationType.apiKey,
    apiKeyName: name,
    apiKeyValue: value,
    apiKeyPlacement: ApiKeyPlacement.queryParam,
  );
}
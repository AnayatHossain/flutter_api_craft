/// HTTP method types supported by [FlutterApiCraft].
///
/// Maps directly to the method selector in Postman.
enum ApiType {
  /// HTTP GET — retrieve a resource.
  get,

  /// HTTP POST — create a resource or submit data.
  post,

  /// HTTP PUT — replace a resource entirely.
  put,

  /// HTTP PATCH — partially update a resource.
  patch,

  /// HTTP DELETE — remove a resource.
  delete,

  /// HTTP HEAD — like GET but returns headers only (no body).
  head,

  /// HTTP OPTIONS — query which methods the server supports.
  options,
}

/// Request body types, matching every option in Postman's Body tab.
enum ApiBodyType {
  /// No body is sent.
  none,

  /// `multipart/form-data` — supports text fields and file uploads.
  formData,

  /// `application/x-www-form-urlencoded` — URL-encoded key/value pairs.
  xWwwFormUrlencoded,

  /// Raw text body (JSON, plain text, XML, HTML, or JavaScript).
  raw,

  /// Binary file or byte-array upload.
  binary,

  /// GraphQL query + variables, sent as JSON.
  graphQL,
}

/// Content-type variants for [ApiBodyType.raw] bodies.
enum RawBodyContentType {
  /// `application/json` — auto-encodes Maps and Lists.
  json,

  /// `text/plain`
  text,

  /// `application/xml`
  xml,

  /// `text/html`
  html,

  /// `application/javascript`
  javascript,
}

/// Authorization types, mirroring every option in Postman's Authorization tab.
enum ApiAuthorizationType {
  /// No authorization header is added.
  none,

  /// Inherit the authorization from a parent collection (no-op in code).
  inheritFromParent,

  /// HTTP Basic Auth — sends `Authorization: Basic <base64(user:pass)>`.
  basicAuth,

  /// Bearer token — sends `Authorization: Bearer <token>`.
  bearerToken,

  /// JWT Bearer token — sends `Authorization: Bearer <jwt>`.
  jwtBearer,

  /// HTTP Digest Auth (challenge/response).
  digestAuth,

  /// OAuth 1.0 HMAC/RSA signed requests.
  oauth1,

  /// OAuth 2.0 — sends the access token as `Authorization: Bearer <token>`.
  oauth2,

  /// Hawk authentication scheme.
  hawkAuthentication,

  /// AWS Signature Version 4.
  awsSignature,

  /// NTLM (Windows) authentication.
  ntlmAuthentication,

  /// API Key — placed either in a header or as a query parameter.
  apiKey,

  /// Akamai EdgeGrid signing scheme.
  akamaiEdgeGrid,
}

/// Where to place the API key when using [ApiAuthorizationType.apiKey].
enum ApiKeyPlacement {
  /// Inject the key as a request header.
  header,

  /// Append the key as a URL query parameter.
  queryParam,
}

/// Identifies which script slot to use in [ApiScript].
enum ScriptType {
  /// Runs before the HTTP request is sent.
  preRequest,

  /// Runs after the HTTP response is received.
  postResponse,
}

/// Navigation action to take after a successful API response.
enum NavigationAction {
  /// Do nothing after the request.
  none,

  /// Call `Get.back()` — pop the current screen.
  pop,

  /// Call `Get.until(...)` — pop until a named route.
  popUntil,

  /// Call `Get.toNamed(...)` — push a new named route.
  pushNamed,

  /// Call `Get.offNamed(...)` — replace the current screen.
  pushReplacement,

  /// Call `Get.offAllNamed(...)` — clear stack and push a named route.
  pushAndRemoveUntil,

  /// Call `Get.offAll(...)` — clear stack and push a widget.
  offAll,
}

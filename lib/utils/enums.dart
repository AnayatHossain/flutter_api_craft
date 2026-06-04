/// HTTP Method types
enum ApiType {
  get,
  post,
  put,
  patch,
  delete,
  head,
  options,
}

/// Request body types (mirrors Postman body options)
enum ApiBodyType {
  none,
  formData,
  xWwwFormUrlencoded,
  raw,
  binary,
  graphQL,
}

/// Raw body content types
enum RawBodyContentType {
  json,
  text,
  xml,
  html,
  javascript,
}

/// Authorization types
enum ApiAuthorizationType {
  none,
  inheritFromParent,
  basicAuth,
  bearerToken,
  jwtBearer,
  digestAuth,
  oauth1,
  oauth2,
  hawkAuthentication,
  awsSignature,
  ntlmAuthentication,
  apiKey,
  akamaiEdgeGrid,
}

/// Where to place ApiKey auth
enum ApiKeyPlacement {
  header,
  queryParam,
}

/// Script type
enum ScriptType {
  preRequest,
  postResponse,
}

/// Navigation action after success
enum NavigationAction {
  none,
  pop,
  popUntil,
  pushNamed,
  pushReplacement,
  pushAndRemoveUntil,
  offAll,
}
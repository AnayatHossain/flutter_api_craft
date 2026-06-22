# flutter_api_craft

A Flutter HTTP client package built to eliminate repetitive API controller code across projects. When working on multiple projects simultaneously, writing the same request handling, loading states, error management, and navigation logic over and over became a real bottleneck. This package consolidates all of that into a single, consistent API so you write it once and reuse it everywhere.

---

## Installation

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_api_craft: ^0.0.6
```

Then run:

```bash
flutter pub get
```

---

## Quick Start

```dart
final response = await FlutterApiCraft(
baseUrl: 'https://api.example.com',
path: '/auth/login',
apiType: ApiType.post,
apiBody: ApiBody.json({'email': 'user@example.com', 'password': '123456'}),
enableLoading: true,
).call();

if (response.isSuccess) {
print(response['token']);
}
```

---

## Features

- All HTTP methods: GET, POST, PUT, PATCH, DELETE, HEAD, OPTIONS
- All body types: JSON, form-data, URL-encoded, XML, HTML, GraphQL, binary
- All authorization types: Bearer, Basic, API Key, OAuth 2.0, JWT, Digest, and more
- Pre-request and post-response scripting
- Automatic cookie jar management
- 401 token refresh with automatic retry
- Configurable retry logic on failure
- Loading overlay via `flutter_easyloading`
- Success and error snackbars via GetX
- Post-success navigation via GetX
- Lifecycle callbacks: `onSuccess`, `onError`, `onComplete`
- Injectable HTTP client for unit testing

---

## Usage

### HTTP Methods

```dart
FlutterApiCraft(baseUrl: base, path: '/users', apiType: ApiType.get)
FlutterApiCraft(baseUrl: base, path: '/users', apiType: ApiType.post, ...)
FlutterApiCraft(baseUrl: base, path: '/users/1', apiType: ApiType.put, ...)
FlutterApiCraft(baseUrl: base, path: '/users/1', apiType: ApiType.patch, ...)
FlutterApiCraft(baseUrl: base, path: '/users/1', apiType: ApiType.delete)
```

---

### Request Body

```dart
// JSON
ApiBody.json({'email': 'a@b.com', 'password': '123'})

// Plain text
ApiBody.text('Hello, server!')

// XML
ApiBody.xml('<?xml version="1.0"?><user><name>John</name></user>')

// HTML
ApiBody.html('<h1>Hello</h1>')

// JavaScript
ApiBody.javascript('console.log("hello")')

// URL-encoded
ApiBody.urlEncoded({'username': 'admin', 'password': 'secret'})

// Multipart form-data with file attachments
ApiBody.formData(
fields: {'title': 'My Post'},
files: [
ApiFile(fieldName: 'image', path: 'path/to/image.jpg'), // mobile/desktop
ApiFile(fieldName: 'doc', bytes: bytesList, filename: 'file.pdf'), // any platform (incl. web)
],
)

// GraphQL
ApiBody.graphQL(
query: 'query GetUser(\$id: ID!) { user(id: \$id) { id name } }',
variables: {'id': '123'},
)

// Binary file by path (mobile/desktop)
ApiBody.binaryFile('path/to/file.pdf', mimeType: 'application/pdf')

// Binary bytes (any platform, incl. web)
ApiBody.binaryBytes(bytes, mimeType: 'image/png')
```

---

### Authorization

```dart
// Bearer token
ApiAuthorization.bearer('your-access-token')

// JWT Bearer
ApiAuthorization.jwtBearer('your-jwt-token')

// Basic Auth — username and password are Base64-encoded automatically
ApiAuthorization.basic(user: 'admin', pass: 'secret')

// API Key in request header
ApiAuthorization.apiKeyHeader(name: 'X-API-Key', value: 'abc123')

// API Key as query parameter (?api_key=abc123)
ApiAuthorization.apiKeyQuery(name: 'api_key', value: 'abc123')

// OAuth 2.0 with existing access token
ApiAuthorization.oauth2Token('access-token', prefix: 'Bearer')

// OAuth 2.0 full configuration
ApiAuthorization(
type: ApiAuthorizationType.oauth2,
oauth2AccessToken: 'token',
oauth2HeaderPrefix: 'Bearer',
oauth2ClientId: 'client-id',
oauth2Scope: 'read write',
)
```

---

### Query Parameters

```dart
// Simple key-value parameters
ApiParams.simple({'page': '1', 'limit': '10'})

// Multi-value parameters — same key, multiple values
ApiParams(
query: {'sort': 'asc'},
multiQuery: {'tags': ['flutter', 'dart', 'mobile']},
)
// Resulting URL: ?sort=asc&tags=flutter&tags=dart&tags=mobile
```

---

### Custom Headers

```dart
FlutterApiCraft(
baseUrl: base,
path: '/endpoint',
apiHeaders: {
'X-Custom-Header': 'custom-value',
'Accept-Language': 'en-US',
'X-Request-ID': '12345',
},
)
```

---

### Pre-request and Post-response Scripts

Execute custom logic before a request is sent or after a response is received, similar to Postman scripts.

```dart
ApiScript(
preRequest: ({required headers, required params, required body}) async {
headers['X-Timestamp'] = DateTime.now().toIso8601String();
headers['X-Signature'] = generateHmac(body);
params['nonce'] = generateNonce();
},
postResponse: ({required statusCode, required responseBody, required headers}) async {
if (statusCode == 200) {
await saveToCache(responseBody);
}
},
)
```

---

### Cookie Management

```dart
// Login — the response Set-Cookie header is stored automatically
await FlutterApiCraft(
baseUrl: base,
path: '/auth/login',
apiType: ApiType.post,
apiCookies: ApiCookies(enableCookieJar: true),
).call();

// Subsequent requests — stored cookies are forwarded automatically
await FlutterApiCraft(
baseUrl: base,
path: '/dashboard',
apiCookies: ApiCookies(
enableCookieJar: true,
extraCookies: {'theme': 'dark'},
),
).call();

// Clear cookies for a specific domain
CookieManager.instance.clearCookies('api.example.com');

// Clear all stored cookies
CookieManager.instance.clearCookies();
```

---

### Loading Indicator and Snackbars

Requires GetX and flutter_easyloading to be configured in your app.

```dart
FlutterApiCraft(
baseUrl: base,
path: '/submit',
apiType: ApiType.post,
enableLoading: true,
loadingMessage: 'Submitting...',
enableApiSuccessResponseGetSnackBar: true,
enableApiErrorResponseGetSnackBar: true,
snackBarConfig: ApiSnackBarConfig(
successTitle: 'Success',
successMessageKey: 'message',
errorTitle: 'Error',
errorMessageKey: 'error',
duration: Duration(seconds: 4),
borderRadius: 16,
),
)
```

---

### Post-success Navigation

```dart
// Go back to the previous screen
apiSuccessResponseNavigation: ApiSuccessNavigation.pop()

// Push a named route
apiSuccessResponseNavigation: ApiSuccessNavigation.push('/home')

// Replace the current screen
apiSuccessResponseNavigation: ApiSuccessNavigation.replace('/dashboard')

// Clear the entire navigation stack and push a route
apiSuccessResponseNavigation: ApiSuccessNavigation.offAll('/main')

// Navigate only when a condition is met
apiSuccessResponseNavigation: ApiSuccessNavigation(
action: NavigationAction.pushNamed,
routeName: '/verified',
condition: (body) => body['isVerified'] == true,
)
```

---

### Automatic Token Refresh on 401

When the server returns a 401 Unauthorized response, the package calls the provided callback to obtain a new token, then retries the original request exactly once.

```dart
FlutterApiCraft(
baseUrl: base,
path: '/protected-endpoint',
apiAuthorization: ApiAuthorization.bearer(StorageService.getToken()),
onUnauthorizedRefreshToken: () async {
final newToken = await AuthService.refreshToken();
if (newToken != null) {
StorageService.saveToken(newToken);
}
return newToken; // returning null cancels the retry
},
)
```

---

### Retry on Failure

```dart
FlutterApiCraft(
baseUrl: base,
path: '/unstable-endpoint',
retryCount: 3,
retryDelay: Duration(milliseconds: 500),
)
```

---

### Lifecycle Callbacks

```dart
FlutterApiCraft(
baseUrl: base,
path: '/data',
onSuccess: (response) {
controller.updateUI(response.data);
},
onError: (response) {
analytics.logError(response.statusCode);
},
onComplete: () {
// Always called, regardless of outcome
controller.stopLoading();
},
)
```

---

### HTTP Settings

```dart
FlutterApiCraft(
baseUrl: base,
path: '/endpoint',
apiSettings: ApiSettings(
connectTimeout: Duration(seconds: 15),
receiveTimeout: Duration(seconds: 60),
followRedirects: true,
maxRedirects: 5,
verifySslCertificate: true,
),
)
```

---

## ApiResponse

Every call returns an `ApiResponse`. The method never throws.

```dart
final response = await FlutterApiCraft(...).call();

// Status
response.isSuccess       // true when status is 2xx and body success == true
response.statusCode      // HTTP status code, e.g. 200, 404, 500
response.isNetworkError  // true when no HTTP response was received

// Data
response.data            // Parsed response body: Map, List, or String
response['token']        // Shorthand for response.data['token']
response.message         // Reads message / msg / detail from the body
response.rawBody         // Raw response string
response.headers         // Response headers as Map<String, String>

// Error
response.errorMessage    // Extracted or generated error message
response.exception       // The caught exception object, if any
```

---

## Testing

The package exposes an optional `httpClient` parameter on `FlutterApiCraft`. Inject an `http.MockClient` from the `http/testing.dart` library to test without making real network calls.

```dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_api_craft/flutter_api_craft.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('returns a successful response', () async {
    final api = FlutterApiCraft(
      baseUrl: 'https://api.example.com',
      path: '/auth/login',
      apiType: ApiType.post,
      apiBody: ApiBody.json({'email': 'test@test.com', 'password': '123456'}),
      httpClient: MockClient((_) async => http.Response(
        jsonEncode({'message': 'Welcome', 'success': true}),
        200,
        headers: {'content-type': 'application/json'},
      )),
    );

    final response = await api.call();

    expect(response.isSuccess, isTrue);
    expect(response.statusCode, equals(200));
    expect(response['message'], equals('Welcome'));
  });
}
```

Run all tests:

```bash
flutter test
```

Run with coverage:

```bash
flutter test --coverage
```

---

## Project Structure

```
lib/
├── configs/
│   └── request_builder.dart       # Assembles http.BaseRequest from configuration
├── interceptors/
│   ├── authorization_builder.dart # Builds Authorization headers and query params
│   └── cookie_manager.dart        # In-memory cookie jar
├── models/
│   ├── api_authorization.dart     # Authorization configuration
│   ├── api_body.dart              # Request body configuration
│   ├── api_models.dart            # Scripts, cookies, params, navigation, settings
│   └── api_response.dart          # Response model
├── utils/
│   └── enums.dart                 # All enumerations
└── flutter_api_craft.dart         # Main entry point
```

---

## Dependencies

| Package | Purpose |
|---|---|
| http | HTTP request execution |
| get | Snackbars and navigation |
| flutter_easyloading | Full-screen loading overlay |
| shared_preferences | Local storage (reserved for future use) |
| connectivity_plus | Network status (reserved for future use) |

---

## Links

- GitHub: https://github.com/AnayatHossain/flutter_api_craft
- pub.dev: coming soon

---

## License

MIT License. See the LICENSE file for details.
## 0.0.6

- **Flutter web support.** Removed the unconditional `dart:io` import that
  prevented the package from compiling on web. File handling is now platform
  agnostic via a conditional import (`dart:io` on mobile/desktop, a stub on web).
- **Breaking:** `ApiFile.file` (`File`) → `ApiFile.path` (`String`).
- **Breaking:** `ApiBody.binaryFile(File)` → `ApiBody.binaryFile(String path)`.
- On web, use `ApiFile(bytes: ...)` / `ApiBody.binaryBytes(...)`; the path-based
  APIs throw `UnsupportedError` there.

## 0.0.5

- Fixed `pubspec.yaml` description length to meet pub.dev requirements (60–180 characters).
- Removed unnecessary `dart:ui` import from `api_models.dart` (already provided by Flutter).
- Updated `connectivity_plus` constraint to `^7.1.1` to support latest stable version.
- Fixed `dart analyze` inference warnings: added explicit type args to `Future.delayed`, `Get.back`, and GetX navigation methods.
- Fixed `comment_references` lint warnings in doc comments across `enums.dart`, `api_response.dart`, and `api_models.dart`.

## 0.0.4

- Added full `///` documentation comments to all public classes, fields, and methods.
- Added `repository` and `issue_tracker` fields to `pubspec.yaml`.
- Added `topics` to improve pub.dev discoverability.
- Added working `example/` app demonstrating GET, POST, auth, params, and error handling.
- Updated all dependencies to latest stable versions.
- Fixed all `dart analyze` warnings.
- Switched to Dart 3 exhaustive `switch` expressions in `RequestBuilder`.

## 0.0.3

- Added injectable `httpClient` parameter to `FlutterApiCraft` for unit testing.
- Added `isNetworkError` and `message` getters to `ApiResponse`.
- Added `html` and `javascript` body constructors to `ApiBody`.
- Added `oauth2Token` and `jwtBearer` convenience constructors to `ApiAuthorization`.

## 0.0.2

- Export all public classes from the package root so a single import covers the entire API.
- README update with expanded usage examples.

## 0.0.1

- Initial release.
- Supports all HTTP methods (GET, POST, PUT, PATCH, DELETE, HEAD, OPTIONS).
- Supports all Postman body types (none, JSON, form-data, URL-encoded, raw, binary, GraphQL).
- Supports all Postman auth types (Bearer, Basic, JWT, OAuth 1/2, API Key, Digest, Hawk,
  AWS Signature, NTLM, Akamai EdgeGrid).
- Cookie jar, retry logic, and 401 token auto-refresh.
- EasyLoading overlay, GetX snackbars, and post-success navigation.
## 0.0.3

- **Flutter web support.** Removed the unconditional `dart:io` import that
  prevented the package from compiling on web. File handling is now platform
  agnostic via a conditional import (`dart:io` on mobile/desktop, a stub on web).
- **Breaking:** `ApiFile.file` (`File`) → `ApiFile.path` (`String`).
- **Breaking:** `ApiBody.binaryFile(File)` → `ApiBody.binaryFile(String path)`.
- On web, use `ApiFile(bytes: ...)` / `ApiBody.binaryBytes(...)`; the path-based
  APIs throw `UnsupportedError` there.

## 0.0.2

- Readme update.

## 0.0.2

- Export all public classes so a single import covers the entire API.

## 0.0.1

- Initial release.
- Supports all HTTP methods, body types, and authorization schemes.
- Injectable HTTP client for unit testing.
- Cookie jar, retry logic, and 401 token refresh.

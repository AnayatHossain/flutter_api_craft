/// Web stub for `readFileBytes`.
///
/// The web platform has no concept of file system paths, so reading a file by
/// path is unsupported. Provide `ApiFile.bytes` / `ApiBody.binaryBytes`
/// instead (e.g. from `file_picker`'s `bytes`, or an `XFile.readAsBytes()`).
Future<List<int>> readFileBytes(String path) => throw UnsupportedError(
      'flutter_api_craft: reading files by path is not supported on Flutter '
      'web. Use ApiFile(bytes: ...) or ApiBody.binaryBytes(...) instead.',
    );

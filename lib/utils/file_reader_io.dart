import 'dart:io';

/// Reads the bytes of a file from disk.
///
/// This implementation is used on mobile/desktop (where `dart:io` is
/// available). On web, `file_reader_web.dart` is used instead and this
/// import is never pulled in.
Future<List<int>> readFileBytes(String path) => File(path).readAsBytes();

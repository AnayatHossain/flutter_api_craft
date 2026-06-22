/// Cross-platform file reading.
///
/// Picks the `dart:io` implementation on mobile/desktop and a stub that throws
/// [UnsupportedError] on web — so the package compiles and runs on all
/// platforms, including Flutter web.
library;

export 'file_reader_io.dart' if (dart.library.html) 'file_reader_web.dart';

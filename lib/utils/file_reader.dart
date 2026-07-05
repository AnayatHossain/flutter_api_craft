/// Cross-platform file reading.
///
/// Picks the `dart:io` implementation on mobile/desktop and a stub that throws
/// [UnsupportedError] on web — so the package compiles and runs on all
/// platforms, including Flutter web (both JS and Wasm).
///
/// The condition keys off `dart.library.io` (native), defaulting to the web
/// stub. Keying off `dart.library.html` would pull in `dart:io` on Wasm — where
/// neither `dart:html` nor `dart:io` is available — breaking Wasm compilation.
library;

export 'file_reader_web.dart' if (dart.library.io) 'file_reader_io.dart';

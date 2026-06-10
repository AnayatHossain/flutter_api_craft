import 'dart:io';

import '../utils/enums.dart';

/// Holds request body data for all Postman-style body types.
///
/// ## Examples
///
/// ```dart
/// // JSON body
/// ApiBody.json({'email': 'a@b.com', 'password': '123456'})
///
/// // Plain text
/// ApiBody.text('Hello world')
///
/// // XML
/// ApiBody.xml('<root><id>1</id></root>')
///
/// // Form data with text fields + file upload
/// ApiBody.formData(
///   fields: {'title': 'My Post', 'category': 'news'},
///   files: [
///     ApiFile(fieldName: 'avatar', file: File('/path/to/photo.jpg')),
///   ],
/// )
///
/// // URL-encoded
/// ApiBody.urlEncoded({'grant_type': 'password', 'username': 'admin'})
///
/// // GraphQL
/// ApiBody.graphQL(
///   query: 'query GetUser(\$id: ID!) { user(id: \$id) { name email } }',
///   variables: {'id': '42'},
/// )
///
/// // Binary file
/// ApiBody.binaryFile(File('/path/to/report.pdf'), mimeType: 'application/pdf')
/// ```
class ApiBody {
  /// The body type that determines how data is encoded and sent.
  final ApiBodyType type;

  /// Raw body data for [ApiBodyType.raw].
  ///
  /// Pass a [String] (sent as-is) or a [Map]/[List] (auto-serialized to JSON
  /// when [rawContentType] is [RawBodyContentType.json]).
  final dynamic rawData;

  /// Content-type for [ApiBodyType.raw] bodies. Defaults to JSON.
  final RawBodyContentType rawContentType;

  /// Text fields for [ApiBodyType.formData] and
  /// [ApiBodyType.xWwwFormUrlencoded] bodies.
  final Map<String, String>? fields;

  /// File attachments for [ApiBodyType.formData] bodies.
  final List<ApiFile>? files;

  /// GraphQL query string for [ApiBodyType.graphQL] bodies.
  final String? graphQLQuery;

  /// GraphQL variables for [ApiBodyType.graphQL] bodies.
  final Map<String, dynamic>? graphQLVariables;

  /// File for [ApiBodyType.binary] bodies.
  final File? binaryFile;

  /// Raw bytes for [ApiBodyType.binary] bodies (web-compatible).
  final List<int>? binaryBytes;

  /// MIME type for [ApiBodyType.binary] bodies.
  /// Defaults to `application/octet-stream`.
  final String? binaryMimeType;

  /// Creates an [ApiBody] with full control over every field.
  ///
  /// Prefer the named constructors for the common cases.
  const ApiBody({
    this.type = ApiBodyType.none,
    this.rawData,
    this.rawContentType = RawBodyContentType.json,
    this.fields,
    this.files,
    this.graphQLQuery,
    this.graphQLVariables,
    this.binaryFile,
    this.binaryBytes,
    this.binaryMimeType,
  });

  /// JSON body — pass a [Map] or [List]; auto-encoded with `jsonEncode`.
  ///
  /// Sets `Content-Type: application/json`.
  const ApiBody.json(dynamic data)
      : this(
          type: ApiBodyType.raw,
          rawData: data,
          rawContentType: RawBodyContentType.json,
        );

  /// Plain-text body.
  ///
  /// Sets `Content-Type: text/plain`.
  const ApiBody.text(String text)
      : this(
          type: ApiBodyType.raw,
          rawData: text,
          rawContentType: RawBodyContentType.text,
        );

  /// XML body.
  ///
  /// Sets `Content-Type: application/xml`.
  const ApiBody.xml(String xml)
      : this(
          type: ApiBodyType.raw,
          rawData: xml,
          rawContentType: RawBodyContentType.xml,
        );

  /// HTML body.
  ///
  /// Sets `Content-Type: text/html`.
  const ApiBody.html(String html)
      : this(
          type: ApiBodyType.raw,
          rawData: html,
          rawContentType: RawBodyContentType.html,
        );

  /// JavaScript body.
  ///
  /// Sets `Content-Type: application/javascript`.
  const ApiBody.javascript(String js)
      : this(
          type: ApiBodyType.raw,
          rawData: js,
          rawContentType: RawBodyContentType.javascript,
        );

  /// `multipart/form-data` with optional text fields and file attachments.
  ///
  /// Use for profile photo uploads, document submissions, etc.
  const ApiBody.formData({
    Map<String, String>? fields,
    List<ApiFile>? files,
  }) : this(
          type: ApiBodyType.formData,
          fields: fields,
          files: files,
        );

  /// `application/x-www-form-urlencoded` — URL-encoded key/value pairs.
  const ApiBody.urlEncoded(Map<String, String> fields)
      : this(type: ApiBodyType.xWwwFormUrlencoded, fields: fields);

  /// GraphQL body — serialized as `{"query": "...", "variables": {...}}`.
  ///
  /// Sets `Content-Type: application/json`.
  const ApiBody.graphQL({
    required String query,
    Map<String, dynamic>? variables,
  }) : this(
          type: ApiBodyType.graphQL,
          graphQLQuery: query,
          graphQLVariables: variables,
        );

  /// Binary file upload from a [File] object (mobile/desktop).
  ApiBody.binaryFile(File file, {String? mimeType})
      : this(
          type: ApiBodyType.binary,
          binaryFile: file,
          binaryMimeType: mimeType ?? 'application/octet-stream',
        );

  /// Binary upload from raw bytes (web-compatible).
  const ApiBody.binaryBytes(List<int> bytes, {String? mimeType})
      : this(
          type: ApiBodyType.binary,
          binaryBytes: bytes,
          binaryMimeType: mimeType ?? 'application/octet-stream',
        );
}

/// A single file attachment for [ApiBody.formData] requests.
///
/// Exactly one of [file] (disk-based) or [bytes] (in-memory) must be provided.
///
/// ```dart
/// // From a file on disk (e.g. image_picker result)
/// ApiFile(fieldName: 'avatar', file: File('/path/photo.jpg'))
///
/// // From raw bytes (e.g. web platform)
/// ApiFile(fieldName: 'doc', bytes: pdfBytes, filename: 'report.pdf')
/// ```
class ApiFile {
  /// The form field name, e.g. `"avatar"` or `"document"`.
  final String fieldName;

  /// File read from disk. Use with `image_picker` or `file_picker` results.
  final File? file;

  /// Raw bytes for the file. Use on web or when you already have the bytes.
  final List<int>? bytes;

  /// Optional filename override sent in the multipart header.
  /// If null, the file's basename is used.
  final String? filename;

  /// Optional MIME type, e.g. `"image/jpeg"` or `"application/pdf"`.
  final String? mimeType;

  /// Creates an [ApiFile]. Either [file] or [bytes] must be provided.
  const ApiFile({
    required this.fieldName,
    this.file,
    this.bytes,
    this.filename,
    this.mimeType,
  }) : assert(
          file != null || bytes != null,
          'ApiFile: either file or bytes must be provided',
        );
}

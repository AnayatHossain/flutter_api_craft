import '../utils/enums.dart';

/// Holds request body data for all Postman-style body types.
///
/// This class is platform-agnostic and works on mobile, desktop **and web**.
/// File uploads are referenced either by a file-system [String] path
/// (mobile/desktop only) or by raw bytes (all platforms, including web).
///
/// Usage examples:
/// ```dart
/// // JSON body
/// ApiBody.json({'email': 'a@b.com', 'password': '123'})
///
/// // Form data with files (path is mobile/desktop only)
/// ApiBody.formData(
///   fields: {'title': 'My Post'},
///   files: [ApiFile(fieldName: 'image', path: 'path/to/image.jpg')],
/// )
///
/// // Form data with bytes (works everywhere, incl. web)
/// ApiBody.formData(
///   files: [ApiFile(fieldName: 'image', bytes: imageBytes, filename: 'i.jpg')],
/// )
///
/// // URL encoded
/// ApiBody.urlEncoded({'grant_type': 'password', 'username': 'admin'})
///
/// // GraphQL
/// ApiBody.graphQL(
///   query: 'query { users { id name } }',
///   variables: {'limit': 10},
/// )
///
/// // Binary file by path (mobile/desktop)
/// ApiBody.binaryFile('path/to/file.pdf')
///
/// // Binary bytes (works everywhere, incl. web)
/// ApiBody.binaryBytes(bytes, mimeType: 'application/pdf')
/// ```
class ApiBody {
  final ApiBodyType type;

  // ── Raw ───────────────────────────────────────────────────────────────────
  final dynamic rawData; // String, Map, List — auto-serialized based on rawContentType
  final RawBodyContentType rawContentType;

  // ── Form data / URL encoded ───────────────────────────────────────────────
  final Map<String, String>? fields;
  final List<ApiFile>? files; // Only used with formData

  // ── GraphQL ───────────────────────────────────────────────────────────────
  final String? graphQLQuery;
  final Map<String, dynamic>? graphQLVariables;

  // ── Binary ────────────────────────────────────────────────────────────────
  /// File-system path for a binary upload. Mobile/desktop only — on web the
  /// file is read at request-build time and will throw. Use [binaryBytes] on
  /// web instead.
  final String? binaryFilePath;
  final List<int>? binaryBytes;
  final String? binaryMimeType;

  const ApiBody({
    this.type = ApiBodyType.none,
    this.rawData,
    this.rawContentType = RawBodyContentType.json,
    this.fields,
    this.files,
    this.graphQLQuery,
    this.graphQLVariables,
    this.binaryFilePath,
    this.binaryBytes,
    this.binaryMimeType,
  });

  // ── Convenience constructors ──────────────────────────────────────────────

  /// JSON body — pass a Map or List, auto-encoded to JSON.
  const ApiBody.json(dynamic data)
      : this(
    type: ApiBodyType.raw,
    rawData: data,
    rawContentType: RawBodyContentType.json,
  );

  /// Plain text body.
  const ApiBody.text(String text)
      : this(
    type: ApiBodyType.raw,
    rawData: text,
    rawContentType: RawBodyContentType.text,
  );

  /// XML body.
  const ApiBody.xml(String xml)
      : this(
    type: ApiBodyType.raw,
    rawData: xml,
    rawContentType: RawBodyContentType.xml,
  );

  /// HTML body.
  const ApiBody.html(String html)
      : this(
    type: ApiBodyType.raw,
    rawData: html,
    rawContentType: RawBodyContentType.html,
  );

  /// JavaScript body.
  const ApiBody.javascript(String js)
      : this(
    type: ApiBodyType.raw,
    rawData: js,
    rawContentType: RawBodyContentType.javascript,
  );

  /// multipart/form-data with optional text fields and file attachments.
  const ApiBody.formData({
    Map<String, String>? fields,
    List<ApiFile>? files,
  }) : this(
    type: ApiBodyType.formData,
    fields: fields,
    files: files,
  );

  /// application/x-www-form-urlencoded body.
  const ApiBody.urlEncoded(Map<String, String> fields)
      : this(type: ApiBodyType.xWwwFormUrlencoded, fields: fields);

  /// GraphQL body with query and optional variables.
  const ApiBody.graphQL({
    required String query,
    Map<String, dynamic>? variables,
  }) : this(
    type: ApiBodyType.graphQL,
    graphQLQuery: query,
    graphQLVariables: variables,
  );

  /// Binary file upload from a file-system [path] (mobile/desktop only).
  ///
  /// On Flutter web there are no file paths — use [ApiBody.binaryBytes] there.
  const ApiBody.binaryFile(String path, {String? mimeType})
      : this(
    type: ApiBodyType.binary,
    binaryFilePath: path,
    binaryMimeType: mimeType ?? 'application/octet-stream',
  );

  /// Binary upload from raw bytes.
  const ApiBody.binaryBytes(List<int> bytes, {String? mimeType})
      : this(
    type: ApiBodyType.binary,
    binaryBytes: bytes,
    binaryMimeType: mimeType ?? 'application/octet-stream',
  );
}

/// A file attachment for multipart/form-data requests.
/// Either [path] or [bytes] must be provided.
class ApiFile {
  /// The field name in the form (e.g. "avatar", "document").
  final String fieldName;

  /// File-system path. Use this for mobile/desktop file pickers.
  /// Not supported on Flutter web — provide [bytes] there instead.
  final String? path;

  /// Raw bytes. Use this for in-memory files or the web platform.
  final List<int>? bytes;

  /// Optional filename override. If null, the file's basename is used.
  final String? filename;

  /// Optional MIME type (e.g. "image/jpeg", "application/pdf").
  final String? mimeType;

  const ApiFile({
    required this.fieldName,
    this.path,
    this.bytes,
    this.filename,
    this.mimeType,
  }) : assert(
  path != null || bytes != null,
  'ApiFile: either path or bytes must be provided',
  );
}
import 'dart:io';
import '../utils/enums.dart';

/// Holds request body data for all Postman-style body types.
class ApiBody {
  final ApiBodyType type;

  // raw body
  final dynamic rawData; // String, Map, List — auto-serialized
  final RawBodyContentType rawContentType;

  // form-data / x-www-form-urlencoded fields
  final Map<String, String>? fields;

  // form-data file attachments
  final List<ApiFile>? files;

  // GraphQL
  final String? graphQLQuery;
  final Map<String, dynamic>? graphQLVariables;

  // binary
  final File? binaryFile;
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
    this.binaryFile,
    this.binaryBytes,
    this.binaryMimeType,
  });

  // ── Convenience constructors ──────────────────────────────────────────────

  /// JSON body — pass a Map or List; auto-encoded to JSON string.
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

  /// multipart/form-data (fields + optional files).
  const ApiBody.formData({
    Map<String, String>? fields,
    List<ApiFile>? files,
  }) : this(
    type: ApiBodyType.formData,
    fields: fields,
    files: files,
  );

  /// application/x-www-form-urlencoded.
  const ApiBody.urlEncoded(Map<String, String> fields)
      : this(type: ApiBodyType.xWwwFormUrlencoded, fields: fields);

  /// GraphQL body.
  const ApiBody.graphQL({
    required String query,
    Map<String, dynamic>? variables,
  }) : this(
    type: ApiBodyType.graphQL,
    graphQLQuery: query,
    graphQLVariables: variables,
  );

  /// Binary file upload.
  ApiBody.binaryFile(File file, {String? mimeType})
      : this(
    type: ApiBodyType.binary,
    binaryFile: file,
    binaryMimeType: mimeType ?? 'application/octet-stream',
  );

  /// Binary bytes upload.
  const ApiBody.binaryBytes(List<int> bytes, {String? mimeType})
      : this(
    type: ApiBodyType.binary,
    binaryBytes: bytes,
    binaryMimeType: mimeType ?? 'application/octet-stream',
  );
}

/// A file attachment for multipart/form-data requests.
class ApiFile {
  final String fieldName;
  final File? file;
  final List<int>? bytes;
  final String? filename;
  final String? mimeType;

  const ApiFile({
    required this.fieldName,
    this.file,
    this.bytes,
    this.filename,
    this.mimeType,
  }) : assert(
  file != null || bytes != null,
  'Either file or bytes must be provided',
  );
}
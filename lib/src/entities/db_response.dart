import 'package:couchdb_dart/couchdb.dart';

/// Only provided for backward compatibility
@Deprecated('Use ApiResponse instead')
class DbResponse extends ApiResponse {
  /// Creates instance of [DbResponse] with [raw] and [json]
  DbResponse(super.json, {Map<String, String>? headers, super.raw})
    : super(headers: headers ?? const <String, String>{});

  /// Returns response with fields that may be returned by `ServerModel`
  /// request methods
  ServerModelResponse serverModelResponse() {
    return ServerModelResponse.from(this);
  }

  /// Returns response with fields that may be returned by `DatabaseModel`
  /// request methods
  DatabaseModelResponse databaseModelResponse() {
    return DatabaseModelResponse.from(this);
  }

  /// Returns response with fields that may be returned by `DocumentModel`
  /// request methods
  DocumentModelResponse documentModelResponse() {
    return DocumentModelResponse.from(this);
  }

  /// Returns response with fields that may be returned by `DesignDocumentModel`
  /// request methods
  DesignDocumentModelResponse designDocumentModelResponse() {
    return DesignDocumentModelResponse.from(this);
  }

  /// Returns response with fields that may be returned by `LocalDocumentModel`
  /// request methods
  LocalDocumentModelResponse localDocumentModelResponse() {
    return LocalDocumentModelResponse.from(this);
  }
}

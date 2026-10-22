import 'package:couchdb_dart/couchdb.dart';

/// Only provided for backward compatibility
@Deprecated('Use LocalDocuments instead')
class LocalDocumentModel extends LocalDocuments {
  LocalDocumentModel(super.client);
}

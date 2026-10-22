import 'package:couchdb_dart/couchdb.dart';

/// Only provided for backward compatibility
@Deprecated('Use Documents instead')
class DocumentModel extends Documents {
  DocumentModel(super.client);
}

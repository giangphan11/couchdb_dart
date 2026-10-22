import 'package:couchdb_dart/couchdb.dart';

/// Only provided for backward compatibility
@Deprecated('Use DesignDocuments instead')
class DesignDocumentModel extends DesignDocuments {
  DesignDocumentModel(super.client);
}

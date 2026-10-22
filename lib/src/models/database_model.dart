import 'package:couchdb_dart/couchdb.dart';

/// Only provided for backward compatibility
@Deprecated('Use Databases instead')
class DatabaseModel extends Databases {
  DatabaseModel(super.client);
}

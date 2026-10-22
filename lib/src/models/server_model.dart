import 'package:couchdb_dart/couchdb.dart';

/// Only provided for backward compatibility
@Deprecated('Use Server instead')
class ServerModel extends Server {
  ServerModel(super.client);
}

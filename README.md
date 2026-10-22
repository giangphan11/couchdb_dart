# couchdb_dart

Null-safe CouchDB client for Dart and Flutter. Covers the server, databases,
documents, design documents and local documents APIs.

## Usage

```dart
import 'package:couchdb_dart/couchdb.dart';

Future<void> main() async {
  final client = CouchDbClient(
    username: 'admin',
    password: 'password',
    host: 'localhost',
    port: 5984,
  );
  // or: CouchDbClient.fromString('http://admin:password@localhost:5984')

  final dbs = Databases(client);
  final docs = Documents(client);

  try {
    await dbs.createDb('my_db');
    final created = await docs.insertDoc('my_db', 'doc1', {'name': 'Alice'});
    final doc = await docs.doc('my_db', 'doc1');
    print(doc.doc?['name']); // Alice

    await docs.deleteDoc('my_db', 'doc1', created.rev!);
  } on CouchDbException catch (e) {
    print('${e.code}: ${e.response?.reason}');
  } finally {
    client.close();
  }
}
```

### Changes feed

```dart
final changes = await Databases(client).changesIn('my_db', feed: 'continuous');
await for (final change in changes) {
  print(change.results?.first ?? change.lastSeq);
}
```

### Authentication

`auth` may be `basic` (default), `cookie` (call `client.authenticate()` first)
or `proxy` (pass `secret`).

### Testing

Pass a custom `http.Client` (e.g. `MockClient` from `package:http/testing.dart`)
via the `httpClient` constructor parameter.
# couchdb_dart

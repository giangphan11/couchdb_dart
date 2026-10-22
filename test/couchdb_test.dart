import 'dart:convert';

import 'package:couchdb_dart/couchdb.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _json = <String, String>{'content-type': 'application/json'};

http.Response _ok(
  Object body, {
  int status = 200,
  Map<String, String>? headers,
}) => http.Response(jsonEncode(body), status, headers: {..._json, ...?headers});

void main() {
  late List<http.BaseRequest> requests;

  CouchDbClient clientWith(
    Future<http.Response> Function(http.Request) handler, {
    String auth = 'basic',
    String? username = 'admin',
    String? password = 'p@ss:word',
  }) {
    requests = <http.BaseRequest>[];
    return CouchDbClient(
      username: username,
      password: password,
      host: 'localhost',
      auth: auth,
      httpClient: MockClient((req) {
        requests.add(req);
        return handler(req);
      }),
    );
  }

  group('CouchDbClient', () {
    test('sends basic auth for credentials with special characters', () async {
      final client = clientWith((_) async => _ok({'couchdb': 'Welcome'}));
      final res = await Server(client).couchDbInfo();

      expect(res.couchDbMessage, 'Welcome');
      expect(requests.single.url.toString(), 'http://localhost:5984/');
      expect(
        requests.single.headers['Authorization'],
        'Basic ${base64Encode(utf8.encode('admin:p@ss:word'))}',
      );
    });

    test('per-request headers do not leak into next requests', () async {
      final client = clientWith((_) async => _ok({'ok': true}));
      await client.get('db', reqHeaders: {'X-Test': '1'});
      await client.get('db');

      expect(requests[0].headers['X-Test'], '1');
      expect(requests[1].headers.containsKey('X-Test'), isFalse);
    });

    test('parses JSON with null values', () async {
      final client = clientWith(
        (_) async => _ok({'_id': 'a', '_rev': '1-x', 'value': null}),
      );
      final res = await Documents(client).doc('db', 'a');

      expect(res.id, 'a');
      expect(res.rev, '1-x');
      expect(res.doc!.containsKey('value'), isTrue);
    });

    test('throws CouchDbException with CouchDB error', () async {
      final client = clientWith(
        (_) async =>
            _ok({'error': 'not_found', 'reason': 'missing'}, status: 404),
      );

      expect(
        () => client.get('db/doc'),
        throwsA(
          isA<CouchDbException>()
              .having((e) => e.code, 'code', 404)
              .having((e) => e.response?.reason, 'reason', 'missing'),
        ),
      );
    });

    test('throws CouchDbException for non-JSON error body', () async {
      final client = clientWith(
        (_) async => http.Response(
          'Bad gateway',
          502,
          headers: {'content-type': 'text/html'},
        ),
      );

      expect(
        () => client.post('db'),
        throwsA(
          isA<CouchDbException>()
              .having((e) => e.code, 'code', 502)
              .having((e) => e.response?.reason, 'reason', 'Bad gateway'),
        ),
      );
    });

    test('headDbInfo throws for missing database', () async {
      final client = clientWith((_) async => http.Response('', 404));

      expect(
        () => Databases(client).headDbInfo('nope'),
        throwsA(
          isA<CouchDbException>().having(
            (e) => e.response?.error,
            'error',
            'Not found',
          ),
        ),
      );
    });

    test('encodes non-map bodies as JSON', () async {
      final client = clientWith((_) async => _ok({'ok': true}));
      await Databases(client).setRevsLimit('db', 500);

      expect((requests.single as http.Request).body, '500');
    });

    test('cookie auth stores only cookie value', () async {
      final client = clientWith(
        (req) async => _ok(
          {'ok': true, 'name': 'admin'},
          headers: {
            'set-cookie': 'AuthSession=abc; Version=1; Path=/; HttpOnly',
          },
        ),
        auth: 'cookie',
      );
      await client.authenticate();
      await client.get('db');

      expect(requests.last.headers['Cookie'], 'AuthSession=abc');
      await client.logout();
      await client.get('db');
      expect(requests.last.headers.containsKey('Cookie'), isFalse);
    });

    test('fromString keeps explicit port and path prefix', () async {
      requests = <http.BaseRequest>[];
      final client = CouchDbClient.fromString(
        'https://user:secret@example.com:6984/couch/',
        httpClient: MockClient((req) async {
          requests.add(req);
          return _ok({'ok': true});
        }),
      );
      await client.get('_up');

      expect(client.username, 'user');
      expect(client.password, 'secret');
      expect(
        requests.single.url.toString(),
        'https://example.com:6984/couch/_up',
      );
    });

    test('fromString uses 5984 when port is omitted', () {
      final client = CouchDbClient.fromString('http://localhost');
      expect(client.port, 5984);
      client.close();
    });

    test('throws when only password is provided', () {
      expect(
        () => CouchDbClient(password: 'x'),
        throwsA(isA<CouchDbException>()),
      );
    });
  });

  group('query parameters', () {
    test('allDocs JSON-encodes keys', () async {
      final client = clientWith((_) async => _ok({'rows': <Object>[]}));
      await Databases(client).allDocs('db', startKey: 'a b', endKey: 'z');

      final params = requests.single.url.queryParameters;
      expect(params['startkey'], '"a b"');
      expect(params['endkey'], '"z"');
    });

    test('view keys are JSON-encoded', () async {
      final client = clientWith(
        (_) async => _ok({'total_rows': 1, 'offset': 0, 'rows': <Object>[]}),
      );
      final res = await DesignDocuments(client).executeViewFunction(
        'db',
        '_design/d',
        'v',
        key: 'k&1',
        keys: <Object>['a', 1],
      );

      final params = requests.single.url.queryParameters;
      expect(params['key'], '"k&1"');
      expect(params['keys'], '["a",1]');
      expect(res.totalRows, 1);
    });
  });

  group('changes feed', () {
    test('normal feed returns all results', () async {
      final client = clientWith(
        (_) async => _ok({
          'results': [
            {
              'seq': '1-a',
              'id': 'doc1',
              'changes': [
                {'rev': '1-x'},
              ],
            },
          ],
          'last_seq': '1-a',
          'pending': 0,
        }),
      );
      final stream = await Databases(client).changesIn('db');
      final res = await stream.single;

      expect(res.results!.single['id'], 'doc1');
      expect(res.lastSeq, '1-a');
      expect(res.pending, 0);
    });

    test('continuous feed emits each change', () async {
      requests = <http.BaseRequest>[];
      final body =
          '{"seq":"1-a","id":"d1","changes":[{"rev":"1-x"}]}\n'
          '\n'
          '{"seq":"2-b","id":"d2","changes":[{"rev":"1-y"}]}\n'
          '{"last_seq":"2-b","pending":0}\n';
      final client = CouchDbClient(
        httpClient: MockClient.streaming((req, _) async {
          requests.add(req);
          // Split body into arbitrary chunks like a real network would
          final bytes = utf8.encode(body);
          return http.StreamedResponse(
            Stream<List<int>>.fromIterable([
              bytes.sublist(0, 10),
              bytes.sublist(10, 70),
              bytes.sublist(70),
            ]),
            200,
            headers: _json,
          );
        }),
      );

      final stream = await Databases(
        client,
      ).changesIn('db', feed: 'continuous');
      final events = await stream.toList();

      expect(requests.single.method, 'GET');
      expect(events.length, 3);
      expect(events[0].results!.single['id'], 'd1');
      expect(events[1].results!.single['id'], 'd2');
      expect(events[2].lastSeq, '2-b');
    });

    test('postChangesIn sends doc_ids', () async {
      final client = clientWith(
        (_) async => _ok({'results': <Object>[], 'last_seq': '0'}),
      );
      final stream = await Databases(
        client,
      ).postChangesIn('db', docIds: ['a', 'b']);
      await stream.drain<void>();

      expect(requests.single.method, 'POST');
      expect(jsonDecode((requests.single as http.Request).body), {
        'doc_ids': ['a', 'b'],
      });
    });
  });

  group('Server', () {
    test('uuids and nodeStats responses are parsed', () async {
      final client = clientWith(
        (req) async => req.url.path == '/_uuids'
            ? _ok({
                'uuids': ['u1', 'u2'],
              })
            : _ok({
                'couchdb': {
                  'open_databases': {'value': 1, 'type': 'counter'},
                },
                'memory': {'total': 10},
              }),
      );
      final server = Server(client);

      expect((await server.uuids(count: 2)).uuids, ['u1', 'u2']);
      final stats = await server.nodeStats();
      expect(stats.couchDbMessage, isNull);
      expect(stats.couchDb!['open_databases']!['value'], 1);
      expect(stats.memory, {'total': 10});
    });

    test('configureCouchDb omits null fields', () async {
      final client = clientWith((_) async => _ok({'ok': true}));
      await Server(
        client,
      ).configureCouchDb(action: 'add_node', host: 'h', port: 5984);

      expect(jsonDecode((requests.single as http.Request).body), {
        'action': 'add_node',
        'port': 5984,
        'host': 'h',
      });
    });
  });
}

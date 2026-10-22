import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import '../interfaces/client_interface.dart';
import '../responses/api_response.dart';
import '../exceptions/couchdb_exception.dart';

/// Client for interacting with database via server-side and web applications
class CouchDbClient implements ClientInterface {
  /// Creates instance of client with [username], [password], [host], [port],
  /// [cors], [auth], [scheme] of the connection and
  /// [secret] (needed for proxy authentication) parameters.
  /// Optional [httpClient] replaces default HTTP client.
  /// Make sure that CouchDb application have `CORS` enabled.
  ///
  /// [auth] may be one of:
  ///
  ///     - basic (default)
  ///     - cookie
  ///     - proxy
  ///
  /// [scheme] may be one of:
  ///
  ///   - http
  ///   - https (if `SSL` set to `true`)
  CouchDbClient({
    String? username,
    String? password,
    String scheme = 'http',
    String host = '0.0.0.0',
    int port = 5984,
    this.auth = 'basic',
    this.cors = false,
    String? secret,
    String? path,
    http.Client? httpClient,
  }) : secret = secret != null ? utf8.encode(secret) : null,
       _httpClient = httpClient ?? http.Client() {
    if (username == null && password != null) {
      throw CouchDbException(
        401,
        response: ApiResponse(<String, Object>{
          'error': 'Authorization failed',
          'reason': 'You must provide username if password is non null!',
        }).errorResponse(),
      );
    } else if (username != null && password == null) {
      throw CouchDbException(
        401,
        response: ApiResponse(<String, Object>{
          'error': 'Authorization failed',
          'reason': 'You must provide password if username is non null!',
        }).errorResponse(),
      );
    }

    final regExp = RegExp(r'http[s]?://');
    if (host.startsWith(regExp)) {
      host = host.replaceFirst(regExp, '');
    }
    _username = username ?? '';
    _password = password ?? '';
    _connectUri = Uri(scheme: scheme, host: host, port: port, path: path);
  }

  /// Create [CouchDbClient] instance from [uri] and
  /// [auth], [cors] and [secret] params.
  ///
  /// If [uri] has no port or has default `80`/`443` port (Dart [Uri]
  /// doesn't distinguish them), port `5984` is used.
  CouchDbClient.fromUri(
    Uri uri, {
    this.auth = 'basic',
    this.cors = false,
    String? secret,
    http.Client? httpClient,
  }) : secret = secret != null ? utf8.encode(secret) : null,
       _httpClient = httpClient ?? http.Client() {
    final separator = uri.userInfo.indexOf(':');
    _username = Uri.decodeComponent(
      separator == -1 ? uri.userInfo : uri.userInfo.substring(0, separator),
    );
    _password = separator == -1
        ? ''
        : Uri.decodeComponent(uri.userInfo.substring(separator + 1));
    _connectUri = Uri(
      scheme: uri.scheme == '' ? 'http' : uri.scheme,
      host: uri.host == '' ? '0.0.0.0' : uri.host,
      port: uri.hasPort ? uri.port : 5984,
      path: uri.path,
    );
  }

  /// Create [CouchDbClient] instance from [uri] and
  /// [auth], [cors] and [secret] params.
  CouchDbClient.fromString(
    String uri, {
    String auth = 'basic',
    bool cors = false,
    String? secret,
    http.Client? httpClient,
  }) : this.fromUri(
         Uri.parse(uri),
         auth: auth,
         cors: cors,
         secret: secret,
         httpClient: httpClient,
       );

  /// Host of database instance
  String get host => _connectUri.host;

  /// Port database listened to
  int get port => _connectUri.port;

  /// Username of database user
  String get username => _username;

  /// Password of database user
  String get password => _password;

  /// Origin to be sent in CORS header
  String get origin => _connectUri.origin;

  /// Base64 encoded [username] and [password]
  String get authCredentials => username.isNotEmpty && password.isNotEmpty
      ? base64Encode(utf8.encode('$username:$password'))
      : '';

  /// Gets unmodifiable request headers of this client
  Map<String, String> get headers => Map<String, String>.unmodifiable(_headers);

  /// Authentication type used in requests
  ///
  /// May be one of:
  ///
  ///     - basic
  ///     - cookie
  ///     - proxy
  ///
  String auth;

  /// Holds authentication cookies
  String? _cookies;

  /// Tells if CORS is enabled
  final bool cors;

  /// Holds secret for proxy authentication
  final List<int>? secret;

  /// Web Client for requests
  ///
  /// May be provided via constructor (e.g. for testing), otherwise
  /// default [http.Client] is used.
  final http.Client _httpClient;

  /// Request headers
  ///
  /// Already contains `Accept` and `Content-Type` headers defaults to `application/json`.
  final Map<String, String> _headers = <String, String>{
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  /// Store connection info about coonection like **scheme**,
  /// **host**, **port** and **path**
  late final Uri _connectUri;

  late final String _username;

  late final String _password;

  /// Origin with optional path prefix (e.g. when CouchDB is behind a proxy)
  String get _baseUrl {
    final path = _connectUri.path.replaceAll(RegExp(r'/+$'), '');
    return '$origin$path';
  }

  // Root is requested with trailing slash: some reverse proxies redirect
  // `/prefix` to `/prefix/`
  Uri _uri(String path) => Uri.parse('$_baseUrl/$path');

  /// Adds [reqHeaders] to the headers sent with every request
  ///
  /// You can directly set your own headers as follows:
  /// ```dart
  /// final client = CouchDbClient(username: 'name', password: 'pass');
  /// client.modifyRequestHeaders(<String, String>{ ... })
  /// ```
  /// or define per-request headers using methods [head], [get], [put],
  /// [post], [delete] and [copy].
  void modifyRequestHeaders(Map<String, String>? reqHeaders) {
    _headers.addAll(reqHeaders ?? <String, String>{});
  }

  /// Builds headers for a single request: client headers, [reqHeaders]
  /// and authentication headers. Doesn't modify client headers.
  Map<String, String> _requestHeaders(Map<String, String>? reqHeaders) {
    final result = <String, String>{..._headers, ...?reqHeaders};

    switch (auth) {
      case 'cookie':
        final cookies = _cookies;
        if (cookies != null) {
          result['Cookie'] = cookies;
        }
        break;
      case 'proxy':
        result['X-Auth-CouchDB-UserName'] = username;
        final secret = this.secret;
        if (secret != null) {
          final encodedUsername = utf8.encode(username);
          result['X-Auth-CouchDB-Token'] = Hmac(
            sha1,
            secret,
          ).convert(encodedUsername).toString();
        }
        break;
      default:
        if (authCredentials.isNotEmpty) {
          result['Authorization'] = 'Basic $authCredentials';
        }
    }
    if (cors) {
      result['Origin'] = origin;
    }
    return result;
  }

  /// Encodes request [body]: strings and bytes are sent as is,
  /// everything else is encoded as JSON
  Object? _encodeBody(Object? body) {
    if (body == null || body is String || body is List<int>) {
      return body;
    }
    return jsonEncode(body);
  }

  /// Decodes response [body] into JSON map
  ///
  /// Non-object JSON values are wrapped: lists into `list` field,
  /// integers into `limit` field. Non-JSON bodies produce empty map.
  Map<String, Object?> _decodeBody(String body) {
    if (body.isEmpty) {
      return <String, Object?>{};
    }
    Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException {
      return <String, Object?>{};
    }
    if (decoded is Map) {
      return Map<String, Object?>.from(decoded);
    } else if (decoded is List) {
      return <String, Object?>{'list': List<Object?>.from(decoded)};
    } else if (decoded is int) {
      return <String, Object?>{'limit': decoded};
    }
    return <String, Object?>{};
  }

  Future<ApiResponse> _handleResponse(http.Response res) async {
    final bodyUTF8 = utf8.decode(res.bodyBytes, allowMalformed: true);

    _checkForErrorStatusCode(
      res.statusCode,
      body: bodyUTF8,
      headers: res.headers,
    );

    final contentType = res.headers['content-type'] ?? '';
    // When body isn't JSON-valid then ApiResponse try parse field from [json]
    // and if it is null - error is thrown
    final json = contentType.contains('json') || contentType.isEmpty
        ? _decodeBody(bodyUTF8)
        : <String, Object?>{};

    return ApiResponse(json, raw: bodyUTF8, headers: res.headers);
  }

  /// HEAD method
  @override
  Future<ApiResponse> head(
    String path, {
    Map<String, String>? reqHeaders,
  }) async {
    final res = await _httpClient.head(
      _uri(path),
      headers: _requestHeaders(reqHeaders),
    );

    _checkForErrorStatusCode(res.statusCode, headers: res.headers);

    return ApiResponse(<String, Object?>{}, headers: res.headers);
  }

  /// GET method
  @override
  Future<ApiResponse> get(
    String path, {
    Map<String, String>? reqHeaders,
  }) async {
    final res = await _httpClient.get(
      _uri(path),
      headers: _requestHeaders(reqHeaders),
    );
    return _handleResponse(res);
  }

  /// PUT method
  @override
  Future<ApiResponse> put(
    String path, {
    Object? body,
    Map<String, String>? reqHeaders,
  }) async {
    final res = await _httpClient.put(
      _uri(path),
      headers: _requestHeaders(reqHeaders),
      body: _encodeBody(body),
    );
    return _handleResponse(res);
  }

  /// POST method
  @override
  Future<ApiResponse> post(
    String path, {
    Object? body,
    Map<String, String>? reqHeaders,
  }) async {
    final res = await _httpClient.post(
      _uri(path),
      headers: _requestHeaders(reqHeaders),
      body: _encodeBody(body),
    );
    return _handleResponse(res);
  }

  /// DELETE method
  @override
  Future<ApiResponse> delete(
    String path, {
    Map<String, String>? reqHeaders,
  }) async {
    final res = await _httpClient.delete(
      _uri(path),
      headers: _requestHeaders(reqHeaders),
    );
    return _handleResponse(res);
  }

  /// COPY method
  @override
  Future<ApiResponse> copy(
    String path, {
    Map<String, String>? reqHeaders,
  }) async {
    final request = http.Request('COPY', _uri(path));
    request.headers.addAll(_requestHeaders(reqHeaders));

    final res = await http.Response.fromStream(await _httpClient.send(request));
    return _handleResponse(res);
  }

  /// Makes request with specific [method] and with long or
  /// continuous connection
  ///
  /// Returns undecoded response.
  @override
  Future<Stream<String>> streamed(
    String method,
    String path, {
    Object? body,
    Map<String, String>? reqHeaders,
  }) async {
    final upperMethod = method.toUpperCase();
    final request = http.Request(upperMethod, _uri(path));
    request.headers.addAll(_requestHeaders(reqHeaders));
    if (body != null && (upperMethod == 'POST' || upperMethod == 'PUT')) {
      request.body = body is Map || body is List
          ? jsonEncode(body)
          : body.toString();
    }
    final res = await _httpClient.send(request);

    if (res.statusCode < 200 || res.statusCode > 202) {
      final errorBody = await res.stream.bytesToString();
      _checkForErrorStatusCode(
        res.statusCode,
        body: errorBody,
        headers: res.headers,
      );
    }

    return res.stream.transform(utf8.decoder);
  }

  /// Checks if response is returned with status codes lower than
  /// `200` of greater than `202`
  ///
  /// Returns `CouchDbException` if status code is out of range `200-202`.
  void _checkForErrorStatusCode(
    int code, {
    String? body,
    Map<String, String>? headers,
  }) {
    if (code < 200 || code > 202) {
      final json = _decodeBody(body ?? '');
      if (!json.containsKey('error')) {
        json['error'] = 'HTTP $code';
        json['reason'] = body == null || body.isEmpty ? null : body;
      }
      throw CouchDbException(
        code,
        response: ApiResponse(
          json,
          headers: headers ?? const <String, String>{},
          raw: body,
        ).errorResponse(),
      );
    }
  }

  /// Closes underlying HTTP client
  ///
  /// The client can't be used after it was closed.
  void close() => _httpClient.close();

  /// Initiates new session for specified user credentials by
  /// providing `Cookie` value
  ///
  /// If [next] parameter was provided the response will trigger redirection
  /// to the specified location in case of successful authentication.
  ///
  /// Structured response is available in `ServerModelResponse`.
  ///
  /// Returns JSON like:
  /// ```json
  /// {'ok': true, 'name': 'root', 'roles': ['_admin']}
  /// ```
  @override
  Future<ApiResponse> authenticate([String? next]) async {
    final path = next != null
        ? '_session?next=${Uri.encodeQueryComponent(next)}'
        : '_session';

    final res = await post(
      path,
      body: <String, String>{'name': username, 'password': password},
    );
    // Keep only `name=value` part, cookie attributes aren't sent back
    _cookies = res.headers['set-cookie']?.split(';').first;
    return res;
  }

  /// Closes user’s session by instructing the browser to clear the cookie
  ///
  /// Structured response is available in `ServerModelResponse`.
  ///
  /// Returns JSON like:
  /// ```json
  /// {'ok': true}
  /// ```
  @override
  Future<ApiResponse> logout() async {
    final res = await delete('_session');
    _cookies = null;
    return res;
  }

  /// Returns information about the authenticated user, including a
  /// User Context Object, the authentication method and database
  /// that were used, and a list of configured
  /// authentication handlers on the server
  ///
  /// Structured response is available in `ServerModelResponse`.
  ///
  /// Returns JSON like:
  /// ```json
  /// {
  ///     'info': {
  ///         'authenticated': 'cookie',
  ///         'authentication_db': '_users',
  ///         'authentication_handlers': [
  ///             'cookie',
  ///             'default'
  ///         ]
  ///     },
  ///     'ok': true,
  ///     'userCtx': {
  ///         'name': 'root',
  ///         'roles': [
  ///             '_admin'
  ///         ]
  ///     }
  /// }
  /// ```
  @override
  Future<ApiResponse> userInfo({bool basic = false}) async {
    final prevAuth = auth;

    if (basic) {
      auth = 'basic';
    }

    try {
      return await get('_session');
    } finally {
      auth = prevAuth;
    }
  }
}

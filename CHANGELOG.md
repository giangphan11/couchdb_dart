## 0.1.0

* Migrated to sound null safety (Dart 3).
* Fixed `package:couchdb` imports to `package:couchdb_dart`.
* Removed `meta` dependency, use caret constraints for `http` and `crypto`.
* `CouchDbClient`:
  * Per-request headers no longer leak into subsequent requests.
  * Responses with `null` JSON values and non-JSON error bodies are handled.
  * Credentials with special characters (`:`, `@`) work for basic auth.
  * `path` option is now applied to request URLs (CouchDB behind a proxy).
  * Cookie auth sends only the cookie value; `logout()` clears it.
  * Request bodies other than `Map` (e.g. `int` for `setRevsLimit`) are JSON-encoded.
  * Added `httpClient` constructor parameter and `close()`.
* Changes feed (`changesIn`, `postChangesIn`) is parsed correctly for
  `normal`, `longpoll`, `continuous` and `eventsource` feeds.
* `key`, `keys`, `startkey`, `endkey`, `atts_since`, `doc_ids`, `open_revs`
  query parameters are JSON-encoded; all query values are URL-encoded.
* `allDesignDocs` `keys` is now `List<String>?`.
* `ServerResponse.history` reads the `history` field (was `results`).
* `configureCouchDb` and `find`/`explain` no longer send `null` fields.

## 0.0.1

* Initial release.

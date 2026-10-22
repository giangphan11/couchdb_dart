import 'dart:convert';

/// Method for including only non-null parameter to path
String includeNonNullParam(String name, Object? value) =>
    value != null ? '$name=${Uri.encodeQueryComponent(value.toString())}' : '';

/// If value != null, returns value as a JSON-encoded value, for use in a url.
/// Otherwise returns an empty string
///
/// Some URL parameters (e.g. startkey and endkey) expect JSON-encoded
/// values rather than bare strings. Mostly this amounts to adding
/// quotation marks on either side of the string and escaping
/// special characters.
String includeNonNullJsonParam(String name, Object? value) =>
    value != null ? '$name=${Uri.encodeQueryComponent(jsonEncode(value))}' : '';

/// Includes `open_revs` parameter: `all` is passed as is,
/// list of revisions is JSON-encoded
String includeOpenRevsParam(Object? value) => value is String
    ? includeNonNullParam('open_revs', value)
    : includeNonNullJsonParam('open_revs', value);

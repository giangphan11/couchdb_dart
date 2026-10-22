import 'error_response.dart';

/// Base class that unit all responses of CouchDB
class ApiResponse {
  /// Creates instance of [ApiResponse] with [raw] and [json]
  ApiResponse(this.json, {this.headers = const <String, String>{}, this.raw});

  /// Field that contain raw body of response
  final String? raw;

  /// Field that contain json itself in order to grab custom fields
  final Map<String, Object?> json;

  /// Headers of response
  final Map<String, String> headers;

  /// Returns error response if exists, otherwise return `null`
  ErrorResponse? errorResponse() {
    if (!isError()) return null;
    return ErrorResponse(
      json['error']?.toString() ?? '',
      json['reason']?.toString() ?? '',
    );
  }

  /// Check if this response is error
  bool isError() => json['error'] != null;

  @override
  String toString() =>
      '''
    json - $json
    raw - $raw
    ''';
}

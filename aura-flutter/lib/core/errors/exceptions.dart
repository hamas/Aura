class ServerException implements Exception {
  final String message;
  final int? statusCode;

  const ServerException(this.message, {this.statusCode});

  @override
  String toString() => 'ServerException: $message (code: $statusCode)';
}

class NetworkException implements Exception {
  final String message;
  const NetworkException([this.message = 'Network error occurred']);

  @override
  String toString() => 'NetworkException: $message';
}

class AddonProtocolException implements Exception {
  final String message;
  const AddonProtocolException(this.message);

  @override
  String toString() => 'AddonProtocolException: $message';
}

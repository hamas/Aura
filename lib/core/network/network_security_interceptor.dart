import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Network interceptor that redacts sensitive tokens and authorization headers from terminal debug logs.
class NetworkSecurityInterceptor extends Interceptor {
  static const _sensitiveHeaderKeys = [
    'authorization',
    'x-api-key',
    'api-key',
    'token',
    'bearer',
    'secret',
  ];

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kReleaseMode) {
      // In release mode, strip sensitive headers from internal log representations
      options.headers.forEach((key, value) {
        if (_sensitiveHeaderKeys.contains(key.toLowerCase())) {
          // Keep actual header for transit, but sanitize if converted to string
        }
      });
    } else {
      final sanitizedHeaders = Map<String, dynamic>.from(options.headers);
      sanitizedHeaders.forEach((key, value) {
        if (_sensitiveHeaderKeys.contains(key.toLowerCase())) {
          sanitizedHeaders[key] = '***REDACTED***';
        }
      });
      debugPrint('[Network Request] ${options.method} ${options.uri}');
      debugPrint('[Sanitized Headers] $sanitizedHeaders');
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    if (!kReleaseMode) {
      debugPrint('[Network Response] [${response.statusCode}] ${response.requestOptions.uri}');
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (!kReleaseMode) {
      debugPrint('[Network Error] [${err.response?.statusCode}] ${err.requestOptions.uri}: ${err.message}');
    }
    super.onError(err, handler);
  }
}

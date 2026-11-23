import 'dart:io';

import 'package:dio/dio.dart';

/// An RFC 9457 problem details answer, or a failure before any answer arrived.
class ApiProblem implements Exception {
  const ApiProblem({
    required this.type,
    required this.title,
    required this.status,
    this.detail,
    this.fieldErrors = const {},
    this.retryAfter,
    this.traceId,
  });

  factory ApiProblem.fromDio(DioException error) {
    final response = error.response;
    if (response == null) {
      return ApiProblem(
        type: 'network',
        title: 'No connection',
        status: 0,
        detail: error.type.name,
      );
    }
    final data = response.data;
    final body = data is Map ? data : const <String, Object?>{};
    final status = response.statusCode ?? 0;
    return ApiProblem(
      type: _text(body['type']) ?? 'about:blank',
      title: _text(body['title']) ?? 'Request failed ($status)',
      status: status,
      detail: _text(body['detail']),
      fieldErrors: _fieldErrors(body['errors']),
      retryAfter: _retryAfter(response.headers.value('retry-after')),
      traceId: _text(body['traceId']),
    );
  }

  /// Returns the problem the interceptor attached, or builds one.
  static ApiProblem of(DioException error) {
    final attached = error.error;
    return attached is ApiProblem ? attached : ApiProblem.fromDio(error);
  }

  final String type;
  final String title;
  final int status;
  final String? detail;

  /// JSON Pointer (for example /title) to the message for that field.
  final Map<String, String> fieldErrors;
  final Duration? retryAfter;
  final String? traceId;

  /// The last part of the type URI, for example validation-error.
  String get kind => type.split('/').last;

  bool get retryable {
    return status == 0 ||
        status >= 500 ||
        status == 408 ||
        status == 425 ||
        status == 429;
  }

  static String? _text(Object? value) => value is String ? value : null;

  static Map<String, String> _fieldErrors(Object? value) {
    if (value is! List) {
      return const {};
    }
    return {
      for (final entry in value)
        if (entry is Map && entry['pointer'] is String && entry['detail'] is String)
          entry['pointer'] as String: entry['detail'] as String,
    };
  }

  static Duration? _retryAfter(String? header) {
    if (header == null) {
      return null;
    }
    final seconds = int.tryParse(header);
    if (seconds != null) {
      return Duration(seconds: seconds);
    }
    try {
      final wait = HttpDate.parse(header).difference(DateTime.now().toUtc());
      return wait.isNegative ? Duration.zero : wait;
    } on HttpException {
      return null;
    } on FormatException {
      return null;
    }
  }

  @override
  String toString() => 'ApiProblem($kind, status $status, trace $traceId)';
}

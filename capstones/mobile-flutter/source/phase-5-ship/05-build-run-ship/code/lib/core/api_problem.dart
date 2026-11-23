import 'dart:io';
import 'package:dio/dio.dart';
import '../l10n/strings.dart';

final class ApiProblem implements Exception {
  const ApiProblem(this.type, this.title, this.status, this.fields, this.retryAt, this.traceId);
  final String type;
  final String title;
  final int status;
  final Map<String, String> fields;
  final DateTime? retryAt;
  final String? traceId;
  String get suffix => type.split('/').last;
  String get message => Strings.text('problem_$suffix') == 'problem_$suffix' ? title : Strings.text('problem_$suffix');
  bool get retryable => status == 0 || status >= 500 || const [408,425,429].contains(status);
  factory ApiProblem.fromDio(DioException error) {
    final response = error.response;
    final data = response?.data;
    final body = data is Map ? data : const {};
    final delay = int.tryParse(response?.headers.value('retry-after') ?? '');
    DateTime? retryDate;
    try { retryDate = HttpDate.parse(response?.headers.value('retry-after') ?? ''); } on FormatException { /* A missing or malformed header has no delay. */ }
    return ApiProblem(body['type'] as String? ?? 'network',
      body['title'] as String? ?? Strings.text('networkError'), response?.statusCode ?? 0,
      {for (final field in body['errors'] as List? ?? const [])
        if (field is Map && field['pointer'] is String && field['detail'] is String)
          field['pointer'] as String: field['detail'] as String},
      delay == null ? retryDate : DateTime.now().add(Duration(seconds: delay)),
      body['traceId'] as String?);
  }
  @override
  String toString() => message;
}

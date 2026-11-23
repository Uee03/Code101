import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/api_problem.dart';

/// Parses every error answer once and logs method, path and status, never headers or bodies.
class ProblemInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final problem = ApiProblem.fromDio(err);
    if (kDebugMode) {
      final request = err.requestOptions;
      debugPrint(
        '${request.method} ${request.uri.path} -> ${problem.status} '
        '${problem.kind} trace=${problem.traceId}',
      );
    }
    handler.next(err.copyWith(error: problem));
  }
}

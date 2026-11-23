import 'package:dio/dio.dart';

import '../../core/api_problem.dart';
import '../../core/auth_errors.dart';
import '../repositories/auth_repository.dart';

/// Adds the bearer token, and after a 401 refreshes once and repeats the call.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._auth, this._dio, {required this.onExpired});

  final AuthRepository _auth;
  final Dio _dio;
  final void Function() onExpired;

  static const _expired = ApiProblem(
    type: 'https://code101.example/problems/unauthorized',
    title: 'Session ended',
    status: 401,
  );
  static const _offline = ApiProblem(
    type: 'network',
    title: 'No connection',
    status: 0,
  );

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.path == '/health') {
      handler.next(options);
      return;
    }
    try {
      final token = await _auth.accessToken();
      options.headers['Authorization'] = 'Bearer $token';
      handler.next(options);
    } on AuthUnavailable {
      handler.reject(DioException(requestOptions: options, error: _offline));
    } on AuthExpired {
      onExpired();
      handler.reject(DioException(requestOptions: options, error: _expired));
    }
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;
    final header = request.headers['Authorization'];
    final alreadyRetried = request.extra['retried'] == true;
    if (err.response?.statusCode != 401 || alreadyRetried || header is! String) {
      handler.next(err);
      return;
    }
    try {
      final token = await _auth.accessToken(rejected: header.substring(7));
      request.headers['Authorization'] = 'Bearer $token';
      request.extra['retried'] = true;
      handler.resolve(await _dio.fetch<dynamic>(request));
    } on AuthExpired {
      onExpired();
      handler.next(err.copyWith(error: _expired));
    } on AuthUnavailable {
      handler.next(err.copyWith(error: _offline));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }
}

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/api_problem.dart';
import '../../core/url_policy.dart';
import '../generated/tasks_api.dart' as generated;
import '../models/item.dart';
import '../repositories/auth_repository.dart';
import 'auth_service.dart';

final class ApiService {
  ApiService(String baseUrl, AuthRepository auth) {
    setBase(baseUrl);
    _dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) async {
      try {
        UrlPolicy.validate(Uri(scheme: options.uri.scheme, host: options.uri.host, port: options.uri.port, path: options.uri.path).toString(), debug: kDebugMode);
        if (options.path != '/health') {
          options.headers['Authorization'] = 'Bearer ${await auth.accessToken()}';
        }
        handler.next(options);
      } on AuthUnavailable {
        handler.reject(DioException(requestOptions: options,
          error: const ApiProblem('network','',0,{},null,null)));
      } catch (_) {
        handler.reject(DioException(requestOptions: options, error: const AuthExpired()));
      }
    }, onError: (error, handler) async {
      final request = error.requestOptions;
      if (error.response?.statusCode == 401 && request.extra['retried'] != true) {
        try {
          final previous = (request.headers['Authorization'] as String).substring(7);
          final next = await auth.accessToken(rejected: previous);
          request.headers['Authorization'] = 'Bearer $next';
          request.extra['retried'] = true;
          handler.resolve(await _dio.fetch<dynamic>(request));
          return;
        } on AuthUnavailable {
          handler.next(error.copyWith(error: const ApiProblem('network','',0,{},null,null)));
          return;
        } catch (_) {
          handler.next(error.copyWith(error: const AuthExpired()));
          return;
        }
      }
      handler.next(error.copyWith(error: ApiProblem.fromDio(error)));
    }));
    _api = generated.TasksApi(_dio);
  }
  final _dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 20), followRedirects: false));
  late final generated.TasksApi _api;
  void setBase(String value) => _dio.options.baseUrl = UrlPolicy.validate(value, debug: kDebugMode).toString().replaceFirst(RegExp(r'/$'), '');
  Map<String, Object?> _json(Object value) => Map<String, Object?>.from(jsonDecode(jsonEncode(value)) as Map);
  Future<T> _call<T>(Future<T> Function() action) async {
    try { return await action(); } on DioException catch (error) {
      throw error.error is ApiProblem ? error.error! : const AuthExpired();
    }
  }
  Future<PageData> page(Query q, {String? cursor}) => _call(() async {
    final Object result = switch (q.kind) {
      'teams' => await _api.teams.listTeams(q: q.search.isEmpty ? null : q.search, limit: 25, cursor: cursor),
      'projects' => await _api.projects.listProjects(teamId: q.parent, archived: q.archived, limit: 25, cursor: cursor),
      'tasks' => await _api.tasks.listTasks(projectId: q.parent, limit: 25, cursor: cursor,
        sort: generated.ListTasksSort.fromJson(q.sort),
        status: q.statuses.isEmpty ? null : q.statuses.split(',').map(generated.TaskStatus.fromJson).toList()),
      'comments' => await _api.comments.listComments(taskId: q.parent, limit: 25, cursor: cursor),
      _ => throw ArgumentError('unknown_resource'),
    };
    return PageData.fromJson(_json(result));
  });
  Future<Item> task(String id) => _call(() async => Item(_json(await _api.tasks.getTask(taskId: id))));
  Future<Map<String, Object?>> me() => _call(() async => _json(await _api.platform.getMe()));
  Future<Map<String, Object?>> health() => _call(() async => _json(await _api.platform.getHealth()));
  Future<void> deleteComment(String id) => _call(() => _api.comments.deleteComment(commentId: id));
  Future<Item> write(String kind, String entity, String parent, Map<String, Object?> body, int? version, String key) => _call(() async {
    final Object result;
    switch (kind) {
      case 'create_task':
        result = await _api.tasks.createTask(projectId: parent, idempotencyKey: key,
          body: generated.TaskCreate.fromJson(body));
      case 'update_task':
        // Generated TaskUpdate cannot distinguish absent from explicit null.
        // Keep this one merge-patch request hand-written, inside the API boundary.
        final response = await _dio.patch<Map<String, dynamic>>('/v1/tasks/${Uri.encodeComponent(entity)}',
          data: body, options: Options(contentType: 'application/merge-patch+json', headers: {'If-Match': '"$version"'}));
        result = response.data!;
      case 'complete_task':
        result = await _api.tasks.completeTask(taskId: entity, ifMatch: '"$version"');
      case 'create_comment':
        result = await _api.comments.createComment(taskId: parent, idempotencyKey: key,
          body: generated.CommentCreate.fromJson(body));
      default: throw ArgumentError('unknown_write');
    }
    return Item(_json(result));
  });
  void dispose() => _dio.close();
}

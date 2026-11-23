import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config.dart';
import '../core/url_policy.dart';
import '../data/local/database.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/task_repository.dart';
import '../data/services/api_service.dart';
import '../data/services/auth_interceptor.dart';
import '../data/services/auth_service.dart';
import '../data/services/connectivity_service.dart';
import '../data/services/problem_interceptor.dart';
import '../data/services/task_local_service.dart';
import '../data/services/token_store.dart';
import '../data/sync/outbox_dao.dart';
import '../data/sync/sync_engine.dart';
import '../features/login/view_model/auth_controller.dart';

final tokenStoreProvider = Provider<TokenStore>((ref) => const TokenStore());

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.watch(authServiceProvider),
    ref.watch(tokenStoreProvider),
  ),
);

final dioProvider = Provider<Dio>((ref) {
  final base = UrlPolicy.validate(Config.apiBase, debug: kDebugMode);
  final dio = Dio(
    BaseOptions(
      baseUrl: base.toString().replaceFirst(RegExp(r'/$'), ''),
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      followRedirects: false,
    ),
  );
  // Order matters: authentication first, then the error parser.
  dio.interceptors.add(
    AuthInterceptor(
      ref.watch(authRepositoryProvider),
      dio,
      onExpired: () => ref.read(authControllerProvider.notifier).expire(),
    ),
  );
  dio.interceptors.add(ProblemInterceptor());
  ref.onDispose(dio.close);
  return dio;
});

final apiServiceProvider = Provider<ApiService>(
  (ref) => ApiService(ref.watch(dioProvider)),
);

/// One database for the whole app, closed when the container is disposed.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final taskLocalServiceProvider = Provider<TaskLocalService>(
  (ref) => TaskLocalService(ref.watch(appDatabaseProvider)),
);

final outboxDaoProvider = Provider<OutboxDao>(
  (ref) => OutboxDao(ref.watch(appDatabaseProvider)),
);

final taskRepositoryProvider = Provider<TaskRepository>(
  (ref) => TaskRepository(
    ref.watch(apiServiceProvider),
    ref.watch(taskLocalServiceProvider),
    ref.watch(outboxDaoProvider),
    ref.watch(appDatabaseProvider),
  ),
);

final connectivityServiceProvider = Provider<ConnectivityService>(
  (ref) => ConnectivityService(),
);

/// true while the phone has a network: the current value first, then every change.
final onlineProvider = StreamProvider<bool>((ref) async* {
  final service = ref.watch(connectivityServiceProvider);
  yield await service.isOnline();
  yield* service.changes;
});

/// How many writes the server has not accepted yet.
final pendingCountProvider = StreamProvider<int>(
  (ref) => ref.watch(outboxDaoProvider).watchCount(),
);

final syncEngineProvider = Provider<SyncEngine>((ref) {
  final engine = SyncEngine(
    db: ref.watch(appDatabaseProvider),
    outbox: ref.watch(outboxDaoProvider),
    tasks: ref.watch(taskLocalServiceProvider),
    api: ref.watch(apiServiceProvider),
    canSync: () => ref.read(authControllerProvider) == AuthStatus.signedIn,
  );
  ref.onDispose(engine.dispose);
  return engine;
});

/// Starts the engine after sign-in and again whenever the network comes back.
/// The app widget watches this provider once, so it lives as long as the app.
final syncRunnerProvider = Provider<void>((ref) {
  final engine = ref.watch(syncEngineProvider);
  ref.listen<AuthStatus>(authControllerProvider, (previous, next) {
    if (next == AuthStatus.signedIn) {
      unawaited(engine.start());
    }
  }, fireImmediately: true);
  ref.listen<AsyncValue<bool>>(onlineProvider, (previous, next) {
    if (next.value == true) {
      unawaited(engine.drain());
    }
  });
});

/// The project shown after sign-in while there is no project picker (lesson 10 adds one).
final defaultProjectIdProvider = Provider<String>((ref) => Config.devProjectId);

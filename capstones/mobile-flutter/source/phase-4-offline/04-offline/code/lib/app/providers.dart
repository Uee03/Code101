import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config.dart';
import '../data/local/cache_store.dart';
import '../data/local/database.dart';
import '../data/sync/outbox_writer.dart';
import '../data/sync/sync_engine.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/collection_repository.dart';
import '../data/repositories/task_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../data/services/auth_service.dart';
import '../data/services/token_store.dart';
import '../data/services/api_service.dart';

final authProvider = Provider<AuthRepository>((ref) {
  final auth = AuthRepository(AuthService(), TokenStore());
  auth.acceptSubject = (subject) async {
    final store = ref.read(storeProvider);
    final previous = await store.setting('owner');
    if (previous != null && previous != subject) {
      if (await store.pendingCount() != 0) throw StateError('differentAccountQueue');
      final base = await store.setting('base_url');
      await store.clear();
      if (base != null) await store.setSetting('base_url',base);
    }
    await store.setSetting('owner',subject);
  };
  ref.onDispose(auth.dispose);
  return auth;
});
final storeProvider = Provider<CacheStore>((ref) {
  final store = AppDatabase(); ref.onDispose(store.close); return store;
});
final apiProvider = Provider<ApiService>((ref) {
  final api = ApiService(Config.apiBase,ref.watch(authProvider)); ref.onDispose(api.dispose); return api;
});
final teamsRepositoryProvider = Provider((ref) => TeamRepository(ref.watch(storeProvider),ref.watch(apiProvider)));
final projectsRepositoryProvider = Provider((ref) => ProjectRepository(ref.watch(storeProvider),ref.watch(apiProvider)));
final commentsRepositoryProvider = Provider((ref) => CommentRepository(ref.watch(storeProvider),ref.watch(apiProvider)));
final writerProvider = Provider<WriteGateway>((ref) => OutboxWriter(ref.watch(storeProvider) as AppDatabase));
final tasksRepositoryProvider = Provider((ref) => TaskRepository(ref.watch(storeProvider),ref.watch(apiProvider),ref.watch(writerProvider)));
final settingsRepositoryProvider = Provider((ref) => SettingsRepository(ref.watch(storeProvider),ref.watch(apiProvider)));

final syncEngineProvider = Provider((ref) => SyncEngine(ref.watch(storeProvider) as AppDatabase,ref.watch(apiProvider),ref.watch(authProvider)));

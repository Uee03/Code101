import '../local/cache_store.dart';
import '../models/item.dart';
import '../services/api_service.dart';

class CollectionRepository {
  CollectionRepository(this.store, this.api);
  final CacheStore store;
  final ApiService api;
  Stream<PageData?> watch(Query q) async* {
    yield await store.page(q);
    await for (final _ in store.changes) { yield await store.page(q); }
  }
  Future<void> refresh(Query q, {String? cursor}) async {
    final page = await api.page(q, cursor: cursor);
    await store.savePage(q, page, append: cursor != null);
  }
}
class TeamRepository extends CollectionRepository { TeamRepository(super.store, super.api); }
class ProjectRepository extends CollectionRepository { ProjectRepository(super.store, super.api); }
class CommentRepository extends CollectionRepository {
  CommentRepository(super.store, super.api);
  Future<void> delete(String id) async { await api.deleteComment(id); await store.remove('comments',id); }
}

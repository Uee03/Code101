import '../local/cache_store.dart';
import '../models/item.dart';
import '../services/api_service.dart';
import 'collection_repository.dart';

abstract interface class WriteGateway {
  Future<Item> write(String kind, String entity, String parent, Map<String, Object?> body, int? version, String key);
}
final class DirectWriter implements WriteGateway {
  DirectWriter(this.api, this.store);
  final ApiService api;
  final CacheStore store;
  @override
  Future<Item> write(String kind, String entity, String parent, Map<String, Object?> body, int? version, String key) async {
    final result = await api.write(kind,entity,parent,body,version,key);
    await store.put(kind == 'create_comment' ? 'comments' : 'tasks',result);
    return result;
  }
}
final class TaskRepository extends CollectionRepository {
  TaskRepository(super.store, super.api, this.writer);
  final WriteGateway writer;
  Future<void> refreshTask(String id) async => store.put('tasks', await api.task(id));
  Stream<Item?> watchTask(String id) async* {
    yield await store.item('tasks',id);
    await for (final _ in store.changes) { yield await store.item('tasks',id); }
  }
  Future<Item> write(String kind, String entity, String parent, Map<String, Object?> body, int? version, String key) =>
    writer.write(kind,entity,parent,body,version,key);
}

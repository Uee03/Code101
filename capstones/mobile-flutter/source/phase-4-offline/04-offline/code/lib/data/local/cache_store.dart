import '../models/item.dart';

abstract interface class CacheStore {
  Stream<void> get changes;
  Future<String> canonicalId(String id);
  Future<PageData?> page(Query q);
  Future<void> savePage(Query q, PageData page, {required bool append});
  Future<Item?> item(String kind, String id);
  Future<void> put(String kind, Item item);
  Future<void> remove(String kind, String id);
  Future<String?> setting(String key);
  Future<void> setSetting(String key, String value);
  Future<int> pendingCount();
  Future<void> clear();
  Future<void> close();
}

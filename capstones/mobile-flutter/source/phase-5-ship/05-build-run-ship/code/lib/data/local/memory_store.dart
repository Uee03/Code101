import 'dart:async';
import '../models/item.dart';
import 'cache_store.dart';

final class MemoryStore implements CacheStore {
  @override
  Future<String> canonicalId(String id) async => id;
  final _pages = <String, (List<String>, String?)>{};
  final _items = <String, Item>{};
  final _settings = <String, String>{};
  final _changes = StreamController<void>.broadcast();
  @override
  Stream<void> get changes => _changes.stream;
  @override
  Future<PageData?> page(Query q) async {
    final stored = _pages[queryKey(q)];
    if (stored == null) return null;
    return PageData(List.unmodifiable(stored.$1.map((id) => _items['${q.kind}/$id']).whereType<Item>()),stored.$2);
  }
  @override
  Future<void> savePage(Query q, PageData value, {required bool append}) async {
    final ids = <String>{if (append) ...?_pages[queryKey(q)]?.$1};
    for (final item in value.items) { _items['${q.kind}/${item.id}'] = item; ids.add(item.id); }
    _pages[queryKey(q)] = (ids.toList(),value.cursor);
    _changes.add(null);
  }
  @override
  Future<Item?> item(String kind, String id) async => _items['$kind/$id'];
  @override
  Future<void> put(String kind, Item value) async { _items['$kind/${value.id}'] = value; _changes.add(null); }
  @override
  Future<void> remove(String kind, String id) async { _items.remove('$kind/$id'); _changes.add(null); }
  @override
  Future<String?> setting(String key) async => _settings[key];
  @override
  Future<void> setSetting(String key, String value) async { _settings[key] = value; }
  @override
  Future<int> pendingCount() async => 0;
  @override
  Future<void> clear() async { _pages.clear(); _items.clear(); _settings.clear(); _changes.add(null); }
  @override
  Future<void> close() => _changes.close();
}

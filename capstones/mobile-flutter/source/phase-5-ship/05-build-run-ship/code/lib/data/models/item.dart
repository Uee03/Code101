import 'dart:convert';

// A frozen domain snapshot. Generated DTOs never escape ApiService.
final class Item {
  Item(Map<String, Object?> value) : json = Map.unmodifiable(value);
  final Map<String, Object?> json;
  String get id => json['id'] as String;
  int get version => json['version'] as int? ?? 0;
  String text(String key) => json[key]?.toString() ?? '';
  String get label => text(json.containsKey('title') ? 'title' : json.containsKey('name') ? 'name' : 'body');
  bool get pending => json['syncState'] != null && json['syncState'] != 'synced';
  String encode() => jsonEncode(json);
}

final class PageData {
  const PageData(this.items, this.cursor);
  final List<Item> items;
  final String? cursor;
  factory PageData.fromJson(Map<String, Object?> json) => PageData(
    List.unmodifiable((json['items'] as List).map((v) => Item(Map<String, Object?>.from(v as Map)))),
    (json['page'] as Map)['nextCursor'] as String?,
  );
}

typedef Query = ({String kind, String parent, String search, bool archived, String statuses, String sort});
Query query(String kind, {String parent = '', String search = '', bool archived = false, String statuses = '', String sort = '-createdAt'}) =>
  (kind: kind, parent: parent, search: search, archived: archived, statuses: statuses, sort: sort);
String queryKey(Query q) => jsonEncode([q.kind,q.parent,q.search,q.archived,q.statuses,q.sort]);

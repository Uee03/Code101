import 'dart:convert';
import 'package:drift/drift.dart' hide Query;
import 'package:drift_flutter/drift_flutter.dart';
import '../models/item.dart';
import 'cache_store.dart';

part 'database.g.dart';

@DriftDatabase(include: {'schema.drift'})
class AppDatabase extends _$AppDatabase implements CacheStore {
  AppDatabase() : super(driftDatabase(name: 'tasksteams',native: const DriftNativeOptions(shareAcrossIsolates:true)));
  @override
  int get schemaVersion => 1;
  @override
  MigrationStrategy get migration => MigrationStrategy(onCreate: (m) => m.createAll(),
    beforeOpen: (_) async { await customStatement('PRAGMA journal_mode=WAL'); await customStatement('PRAGMA busy_timeout=5000'); });
  TableInfo _table(String kind) => switch(kind) {
    'teams' => teams, 'projects' => projects, 'tasks' => tasks, 'comments' => comments,
    _ => throw ArgumentError('unknown_table'),
  };
  @override
  Stream<void> get changes => tableUpdates(TableUpdateQuery.onAllTables([teams,projects,tasks,comments,outbox,cachedPages,appSettings])).map((_) {});
  @override
  Future<String> canonicalId(String id) async => await setting('alias.$id') ?? id;
  @override
  Future<String?> setting(String key) async => (await customSelect('SELECT value FROM app_settings WHERE key = ?',variables:[Variable(key)]).getSingleOrNull())?.read<String>('value');
  @override
  Future<void> setSetting(String key,String value) async {
    await customInsert('INSERT INTO app_settings(key,value) VALUES (?,?) ON CONFLICT(key) DO UPDATE SET value=excluded.value',
      variables:[Variable(key),Variable(value)],updates:{appSettings});
  }
  @override
  Future<Item?> item(String kind,String id) async {
    _table(kind);
    final row = await customSelect('SELECT payload_json FROM $kind WHERE id = ?',variables:[Variable(await canonicalId(id))]).getSingleOrNull();
    return row == null ? null : Item(Map<String,Object?>.from(jsonDecode(row.read<String>('payload_json')) as Map));
  }
  @override
  Future<void> put(String kind,Item value) async {
    final table = _table(kind);
    final j = value.json;
    final columns = <String,Object?>{'id':value.id,'payload_json':value.encode()};
    final names = switch(kind) {
      'teams' => {'name':'name','description':'description','member_count':'memberCount','version':'version','updated_at':'updatedAt'},
      'projects' => {'team_id':'teamId','key':'key','name':'name','description':'description','archived':'archived','version':'version'},
      'tasks' => {'project_id':'projectId','title':'title','description':'description','status':'status','priority':'priority','assignee_id':'assigneeId','due_date':'dueDate','completed_at':'completedAt','version':'version','created_at':'createdAt','sync_state':'syncState','server_json':'serverJson'},
      'comments' => {'task_id':'taskId','body':'body','created_at':'createdAt','sync_state':'syncState'},
      _ => <String,String>{},
    };
    for (final e in names.entries) {
      Object? v = j[e.value];
      if (e.key == 'sync_state') v ??= 'synced';
      if (e.key == 'member_count' || e.key == 'version') v ??= 0;
      if (e.key == 'archived') v = v == true ? 1 : 0;
      if (e.key == 'server_json' && v != null) v = jsonEncode(v);
      if (v == null && !const ['assignee_id','due_date','completed_at','server_json'].contains(e.key)) v = '';
      columns[e.key] = v;
    }
    if (kind == 'comments') {
      final author = j['author'] as Map? ?? {};
      columns.addAll({'author_id':author['id'] ?? '', 'author_name':author['displayName'] ?? ''});
    }
    final keys = columns.keys.toList();
    await customInsert('INSERT INTO $kind (${keys.join(',')}) VALUES (${keys.map((_) => '?').join(',')}) ON CONFLICT(id) DO UPDATE SET ${keys.where((k) => k != 'id').map((k) => '$k=excluded.$k').join(',')}',
      variables:columns.values.map((v) => Variable(v)).toList(),updates:{table});
  }
  @override
  Future<void> remove(String kind,String id) async {
    await customUpdate('DELETE FROM $kind WHERE id=?',variables:[Variable(id)],updates:{_table(kind)});
  }
  @override
  Future<PageData?> page(Query q) async {
    final page = await customSelect('SELECT * FROM cached_pages WHERE page_key=?',variables:[Variable(queryKey(q))]).getSingleOrNull();
    final ids = <String>{if (page != null) ...(jsonDecode(page.read<String>('ids')) as List).cast<String>()};
    final items = <Item>[];
    final parent = await canonicalId(q.parent);
    if (const ['tasks','comments'].contains(q.kind)) {
      final column = q.kind == 'tasks' ? 'project_id' : 'task_id';
      final pending = await customSelect('SELECT id FROM ${q.kind} WHERE $column=? AND sync_state != ?',variables:[Variable(parent),const Variable('synced')]).get();
      ids.addAll(pending.map((row) => row.read<String>('id')));
    }
    for (final id in ids) {
      final entity = await item(q.kind,id);
      if (entity == null) continue;
      if (q.kind == 'tasks' && q.statuses.isNotEmpty && !q.statuses.split(',').contains(entity.text('status'))) continue;
      items.add(entity);
    }
    if (page == null && items.isEmpty) return null;
    if (q.kind == 'tasks') { items.sort((a,b) {
      final field = q.sort == 'dueDate' ? 'dueDate' : 'createdAt';
      final av = a.text(field), bv = b.text(field);
      if (field == 'dueDate' && (av.isEmpty || bv.isEmpty)) return av.isEmpty == bv.isEmpty ? a.id.compareTo(b.id) : av.isEmpty ? 1 : -1;
      final compared = av.compareTo(bv);
      final tie = compared == 0 ? a.id.compareTo(b.id) : compared;
      return q.sort.startsWith('-') ? -tie : tie;
    });
    }
    return PageData(List.unmodifiable(items),page?.readNullable<String>('next_cursor'));
  }
  @override
  Future<void> savePage(Query q,PageData value,{required bool append}) => transaction(() async {
    final old = append ? await page(q) : null;
    if (!append && q.kind == 'tasks') {
      await customUpdate("DELETE FROM tasks WHERE project_id=? AND sync_state='synced'",
        variables:[Variable(await canonicalId(q.parent))],updates:{tasks});
    }
    final ids = <String>{if (old != null) ...old.items.map((item) => item.id)};
    for (final entity in value.items) {
      final local = await item(q.kind,entity.id);
      if (local == null || !local.pending) await put(q.kind,entity);
      ids.add(entity.id);
    }
    await customInsert('INSERT INTO cached_pages(page_key,ids,next_cursor) VALUES (?,?,?) ON CONFLICT(page_key) DO UPDATE SET ids=excluded.ids,next_cursor=excluded.next_cursor',
      variables:[Variable(queryKey(q)),Variable(jsonEncode(ids.toList())),Variable(value.cursor)],updates:{cachedPages});
  });
  @override
  Future<int> pendingCount() async => (await customSelect('SELECT count(*) AS n FROM outbox').getSingle()).read<int>('n');
  @override
  Future<void> clear() => transaction(() async {
    for (final table in <TableInfo>[cachedPages,outbox,comments,tasks,projects,teams,appSettings]) {
      await customUpdate('DELETE FROM ${table.actualTableName}',updates:{table});
    }
  });
}

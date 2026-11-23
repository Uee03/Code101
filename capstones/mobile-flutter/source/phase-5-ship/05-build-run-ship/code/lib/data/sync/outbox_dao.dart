import 'dart:convert';
import 'package:drift/drift.dart';
import '../local/database.dart';
import '../models/item.dart';

final class PendingWrite {
  PendingWrite(QueryRow row) : id=row.read<String>('id'),kind=row.read<String>('kind'),entity=row.read<String>('entity_id'),
    parent=row.read<String>('parent_id'),version=row.readNullable<int>('base_version'),state=row.read<String>('state'),
    attempts=row.read<int>('attempts'),next=row.read<int>('next_attempt_at'),
    payload=Map<String,Object?>.from(jsonDecode(row.read<String>('payload')) as Map),
    problem=row.readNullable<String>('problem_json'),server=row.readNullable<String>('server_json');
  final String id,kind,entity,parent,state;
  final int? version;
  final int attempts,next;
  final Map<String,Object?> payload;
  final String? problem,server;
  Map<String,Object?> get body => Map<String,Object?>.from(payload['body'] as Map);
}
final class OutboxDao {
  OutboxDao(this.db);
  final AppDatabase db;
  Future<List<PendingWrite>> all() async => (await db.customSelect('SELECT * FROM outbox ORDER BY seq').get()).map(PendingWrite.new).toList();
  Future<PendingWrite?> ready() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final row = await db.customSelect("SELECT o.* FROM outbox o WHERE o.state='pending' AND o.next_attempt_at<=? AND NOT EXISTS (SELECT 1 FROM outbox earlier WHERE earlier.entity_id=o.entity_id AND earlier.seq<o.seq) ORDER BY o.seq LIMIT 1",variables:[Variable(now)]).getSingleOrNull();
    return row == null ? null : PendingWrite(row);
  }
  Future<void> update(String id,String state,{int? attempts,int? next,String? problem,String? server}) async {
    await db.customUpdate('UPDATE outbox SET state=?,attempts=coalesce(?,attempts),next_attempt_at=coalesce(?,next_attempt_at),problem_json=?,last_problem_type=?,server_json=? WHERE id=?',
      variables:[Variable(state),Variable(attempts),Variable(next),Variable(problem),Variable(problem == null ? null : (jsonDecode(problem) as Map)['type'] as String?),Variable(server),Variable(id)],updates:{db.outbox});
  }
  Future<bool> lease(String owner) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final n = await db.customUpdate("INSERT INTO sync_leases(name,owner,expires) VALUES ('drain',?,?) ON CONFLICT(name) DO UPDATE SET owner=excluded.owner,expires=excluded.expires WHERE sync_leases.expires<? OR sync_leases.owner=?",
      variables:[Variable(owner),Variable(now+90000),Variable(now),Variable(owner)]);
    return n == 1;
  }
  Future<void> release(String owner) async {
    await db.customUpdate('DELETE FROM sync_leases WHERE owner=?',variables:[Variable(owner)]);
  }
  Future<void> recover() async {
    await db.customUpdate("UPDATE outbox SET state='pending' WHERE state='in_flight'",updates:{db.outbox});
  }
  Future<void> remove(String id) async { await db.customUpdate('DELETE FROM outbox WHERE id=?',variables:[Variable(id)],updates:{db.outbox}); }
  Future<void> retry(String id) => update(id,'pending',next:0);
  Future<void> resolve(PendingWrite row,Set<String> keep) => db.transaction(() async {
    final latest = Item(Map<String,Object?>.from(jsonDecode(row.server!) as Map));
    final body = {for (final e in row.body.entries) if (keep.contains(e.key)) e.key:e.value};
    if (body.isEmpty) { await remove(row.id); }
    else {
      await db.customUpdate("UPDATE outbox SET payload=?,base_version=?,state='pending',next_attempt_at=0,attempts=0,problem_json=NULL,server_json=NULL WHERE id=?",
        variables:[Variable(jsonEncode({'body':body,'before':latest.json})),Variable(latest.version),Variable(row.id)],updates:{db.outbox});
    }
    await db.put('tasks',Item({...latest.json,...body,'syncState':body.isEmpty ? 'synced':'pending'}));
  });
  // Discard the entity's whole local chain; never leave dependent writes dangling.
  Future<void> discard(PendingWrite row) => db.transaction(() async {
    final chain = (await all()).where((r) => r.entity == row.entity).toList();
    final before = chain.first.payload['before'];
    for (final pending in await all()) {
      if (pending.entity == row.entity || (before == null && pending.parent == row.entity)) {
        await remove(pending.id);
        if (pending.kind == 'create_comment') await db.remove('comments',pending.entity);
      }
    }
    final table = row.kind == 'create_comment' ? 'comments':'tasks';
    if (before == null) { await db.remove(table,row.entity); }
    else { await db.put(table,Item(Map<String,Object?>.from(before as Map))); }
  });
}

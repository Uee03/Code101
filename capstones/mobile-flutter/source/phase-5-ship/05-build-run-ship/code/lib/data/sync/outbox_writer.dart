import 'dart:convert';
import 'package:drift/drift.dart';
import '../local/database.dart';
import '../models/item.dart';
import '../repositories/task_repository.dart';
import 'outbox_dao.dart';

final class OutboxWriter implements WriteGateway {
  OutboxWriter(this.db);
  final AppDatabase db;
  @override
  Future<Item> write(String kind,String entity,String parent,Map<String,Object?> body,int? version,String key) => db.transaction(() async {
    entity = await db.canonicalId(entity);
    parent = await db.canonicalId(parent);
    final table = kind == 'create_comment' ? 'comments':'tasks';
    final before = await db.item(table,entity);
    final now = DateTime.now().toUtc().toIso8601String();
    final optimistic = Item({
      'id':entity,'createdAt':now,'updatedAt':now,'version':version ?? 0,
      if (kind == 'create_task') ...{'projectId':parent,'createdBy':await db.setting('owner'),'completedAt':null},
      if (kind == 'create_comment') ...{'taskId':parent,'author':{'id':await db.setting('owner'),'displayName':await db.setting('owner_name') ?? ''}},
      ...?before?.json,...body,
      if (kind == 'complete_task') ...{'status':'done','completedAt':now},
      'syncState':'pending',
    });
    await db.put(table,optimistic);
    final all = await OutboxDao(db).all();
    final invalid = all.where((r) => r.entity == entity && r.state == 'failed' &&
      r.problem != null && (jsonDecode(r.problem!) as Map)['status'] == 422);
    if (invalid.isNotEmpty && kind == 'update_task') {
      final failed = invalid.first;
      final corrected = {...failed.body,...body};
      await db.customUpdate("UPDATE outbox SET id=?,payload=?,state='pending',attempts=0,next_attempt_at=0,problem_json=NULL WHERE id=?",
        variables:[Variable(key),Variable(jsonEncode({...failed.payload,'body':corrected})),Variable(failed.id)],updates:{db.outbox});
      return optimistic;
    }
    final creates = all.where((r) => r.entity == entity && r.kind == 'create_task' && r.attempts == 0 && r.state == 'pending');
    if (creates.isNotEmpty && kind != 'create_task') {
      final create = creates.first;
      final merged = {...create.body,...body,if (kind == 'complete_task') 'status':'done'};
      await db.customUpdate('UPDATE outbox SET payload=? WHERE id=?',variables:[Variable(jsonEncode({...create.payload,'body':merged})),Variable(create.id)],updates:{db.outbox});
    } else {
      await db.customInsert("INSERT INTO outbox(id,kind,entity_id,parent_id,payload,base_version,state,created_at) VALUES (?,?,?,?,?,?,'pending',?) ON CONFLICT(id) DO NOTHING",
        variables:[Variable(key),Variable(kind),Variable(entity),Variable(parent),Variable(jsonEncode({'body':body,'before':before?.json})),Variable(version),Variable(now)],updates:{db.outbox});
    }
    return optimistic;
  });
}

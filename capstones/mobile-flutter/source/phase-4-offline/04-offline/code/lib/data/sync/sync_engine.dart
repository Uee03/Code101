import 'dart:convert';
import 'dart:math';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../core/api_problem.dart';
import '../local/database.dart';
import '../models/item.dart';
import '../repositories/auth_repository.dart';
import '../services/api_service.dart';
import 'outbox_dao.dart';

final class SyncEngine {
  SyncEngine(this.db,this.api,this.auth) : dao=OutboxDao(db);
  final AppDatabase db;
  final ApiService api;
  final AuthRepository auth;
  final OutboxDao dao;
  Future<void>? _running;
  Future<void> drain() => _running ??= _drain().whenComplete(() => _running=null);
  Future<void> _drain() async {
    if (auth.signedIn != true) return;
    final owner = const Uuid().v4();
    if (!await dao.lease(owner)) return;
    try {
      await dao.recover();
      for (var n=0;n<100;n++) {
        if (!await dao.lease(owner)) return;
        final row = await dao.ready();
        if (row == null) return;
        await dao.update(row.id,'in_flight',attempts:row.attempts+1);
        try {
          final result = await api.write(row.kind,await db.canonicalId(row.entity),
            await db.canonicalId(row.parent),row.body,row.version,row.id);
          await _accept(row,result);
        } on AuthExpired {
          await dao.update(row.id,'pending');
          return;
        } on ApiProblem catch (problem) {
          if (problem.status == 412) {
            final server = await api.task(await db.canonicalId(row.entity));
            await db.transaction(() async {
              await dao.update(row.id,'conflict',server:server.encode(),problem:jsonEncode({'type':problem.type,'title':problem.title}));
              final mine = await db.item('tasks',row.entity);
              if (mine != null) await db.put('tasks',Item({...mine.json,'syncState':'conflict','serverJson':server.json}));
            });
          } else {
            final exponent = min(row.attempts,10);
            final backoff = min(3600000,1000 * (1 << exponent)) + Random.secure().nextInt(1000);
            final retryAt = problem.retryAt?.millisecondsSinceEpoch ?? 0;
            final next = max(DateTime.now().millisecondsSinceEpoch+backoff,retryAt);
            await dao.update(row.id,problem.retryable ? 'pending':'failed',next:next,
              problem:jsonEncode({'type':problem.type,'title':problem.title,'status':problem.status,'errors':problem.fields,'traceId':problem.traceId}));
            if (!problem.retryable) {
              final table = row.kind == 'create_comment' ? 'comments':'tasks';
              final local = await db.item(table,row.entity);
              if (local != null) await db.put(table,Item({...local.json,'syncState':'failed','fieldErrors':problem.fields}));
            }
            if (problem.status == 0 || problem.status == 429 || problem.status >= 500) return;
          }
        } catch (_) {
          await dao.update(row.id,'pending',next:DateTime.now().millisecondsSinceEpoch+30000);
          return;
        }
      }
    } finally { await dao.release(owner); }
  }
  Future<void> _accept(PendingWrite row,Item server) => db.transaction(() async {
    final table = row.kind == 'create_comment' ? 'comments':'tasks';
    if (row.entity != server.id) {
      await db.setSetting('alias.${row.entity}',server.id);
      await db.remove(table,row.entity);
      await db.customUpdate('UPDATE outbox SET entity_id=? WHERE entity_id=?',variables:[Variable(server.id),Variable(row.entity)],updates:{db.outbox});
      await db.customUpdate('UPDATE outbox SET parent_id=? WHERE parent_id=?',variables:[Variable(server.id),Variable(row.entity)],updates:{db.outbox});
      for (final comment in await db.customSelect('SELECT payload_json FROM comments WHERE task_id=?',variables:[Variable(row.entity)]).get()) {
        final json = Map<String,Object?>.from(jsonDecode(comment.read<String>('payload_json')) as Map);
        await db.put('comments',Item({...json,'taskId':server.id}));
      }
    }
    await dao.remove(row.id);
    final later = (await dao.all()).where((r) => r.entity == server.id).toList();
    var merged = {...server.json,'syncState':'synced'};
    if (later.isNotEmpty) {
      final first = later.first;
      await db.customUpdate('UPDATE outbox SET base_version=? WHERE id=?',variables:[Variable(server.version),Variable(first.id)],updates:{db.outbox});
      for (final pending in later) {
        merged = {...merged,...pending.body,if (pending.kind == 'complete_task') 'status':'done','syncState':'pending'};
      }
    }
    await db.put(table,Item(merged));
    if (row.kind.startsWith('create_')) {
      for (final page in await db.customSelect('SELECT * FROM cached_pages').get()) {
        final pageKey = page.read<String>('page_key');
        final query = jsonDecode(pageKey) as List;
        if (query[0] != table || await db.canonicalId(query[1] as String) != await db.canonicalId(row.parent)) continue;
        final ids = (jsonDecode(page.read<String>('ids')) as List).cast<String>().toSet();
        ids.remove(row.entity); ids.add(server.id);
        await db.customUpdate('UPDATE cached_pages SET ids=? WHERE page_key=?',
          variables:[Variable(jsonEncode(ids.toList())),Variable(pageKey)],updates:{db.cachedPages});
      }
    }
  });
}

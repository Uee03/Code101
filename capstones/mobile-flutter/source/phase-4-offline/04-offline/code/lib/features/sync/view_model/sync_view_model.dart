import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../data/local/database.dart';
import '../../../data/services/connectivity_service.dart';
import '../../../data/sync/outbox_dao.dart';

final syncViewModelProvider = NotifierProvider<SyncViewModel,SyncState>(SyncViewModel.new);
final class SyncState {
  const SyncState({this.online = true,this.busy = false,this.rows = const []});
  final bool online,busy;
  final List<PendingWrite> rows;
}
class SyncViewModel extends Notifier<SyncState> {
  @override
  SyncState build() {
    final db = ref.read(storeProvider) as AppDatabase;
    final data = db.changes.listen((_) => _reload());
    final connectivity = ConnectivityService();
    final network = connectivity.changes.listen((online) {
      state = SyncState(online:online,busy:state.busy,rows:state.rows);
      if (online) sync();
    });
    final timer = Timer.periodic(const Duration(seconds:5),(_) => sync());
    ref.onDispose(() { data.cancel(); network.cancel(); timer.cancel(); });
    Future.microtask(() async {
      final online = await connectivity.available();
      if (!ref.mounted) return;
      state = SyncState(online:online);
      await _reload();
      if (online) await sync();
    });
    return const SyncState();
  }
  OutboxDao get _dao => OutboxDao(ref.read(storeProvider) as AppDatabase);
  Future<void> _reload() async {
    final rows = await _dao.all();
    if (ref.mounted) state = SyncState(online:state.online,busy:state.busy,rows:List.unmodifiable(rows));
  }
  Future<void> sync() async {
    if (state.busy || !state.online) return;
    state = SyncState(online:state.online,busy:true,rows:state.rows);
    try { await ref.read(syncEngineProvider).drain(); }
    finally { if (ref.mounted) { state = SyncState(online:state.online,rows:state.rows); await _reload(); } }
  }
  Future<void> retry(PendingWrite row) async { await _dao.retry(row.id); await sync(); }
  Future<void> discard(PendingWrite row) => _dao.discard(row);
  Future<void> resolve(PendingWrite row,Set<String> keep) async { await _dao.resolve(row,keep); await sync(); }
}

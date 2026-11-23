import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/item.dart';
import 'api_problem.dart';
import '../data/repositories/collection_repository.dart';

final class CollectionState {
  const CollectionState({this.page, this.loading = true, this.error});
  final PageData? page;
  final bool loading;
  final Object? error;
}
abstract class CollectionViewModel extends Notifier<CollectionState> {
  CollectionViewModel(this.query);
  Query query;
  DateTime? _notBefore;
  CollectionRepository get repository;
  StreamSubscription<PageData?>? _subscription;
  @override
  CollectionState build() {
    ref.onDispose(() => _subscription?.cancel());
    Future.microtask(() => load(query));
    return const CollectionState();
  }
  Future<void> load(Query next) async {
    query = next;
    await _subscription?.cancel();
    state = const CollectionState();
    _subscription = repository.watch(next).listen((page) {
      state = CollectionState(page: page, loading: state.loading, error: state.error);
    });
    await refresh();
  }
  Future<void> refresh({bool next = false}) async {
    if (_notBefore?.isAfter(DateTime.now()) ?? false) return;
    if (next && (state.loading || state.page?.cursor == null)) return;
    final current = query;
    state = CollectionState(page: state.page, loading: true);
    try {
      await repository.refresh(current, cursor: next ? state.page?.cursor : null);
      if (query == current) state = CollectionState(page: state.page, loading: false);
    } catch (error) {
      if (error is ApiProblem && error.status == 429) _notBefore = error.retryAt;
      if (query == current) state = CollectionState(page: state.page, loading: false,error: error);
    }
  }
}

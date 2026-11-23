import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../app/providers.dart';
import '../../../data/models/item.dart';

final detailViewModelProvider = NotifierProvider.autoDispose.family<TaskDetailViewModel,AsyncValue<Item?>,String>(TaskDetailViewModel.new);
class TaskDetailViewModel extends Notifier<AsyncValue<Item?>> {
  TaskDetailViewModel(this.id);
  final String id;
  String _commentKey = const Uuid().v4();
  bool _writing = false;
  String? callerId;
  @override
  AsyncValue<Item?> build() {
    final repository = ref.read(tasksRepositoryProvider);
    final subscription = repository.watchTask(id).listen((item) { state = AsyncData(item); });
    ref.onDispose(subscription.cancel);
    Future.microtask(refresh);
    return const AsyncLoading();
  }
  Future<void> refresh() async {
    try {
      callerId = (await ref.read(settingsRepositoryProvider).account())['id'] as String;
      await ref.read(tasksRepositoryProvider).refreshTask(id);
    } catch (error,stack) {
      if (state.value == null) state = AsyncError(error,stack);
    }
  }
  Future<void> complete() async {
    if (_writing || state.value == null) return;
    _writing = true;
    try {
      final item = state.value!;
      await ref.read(tasksRepositoryProvider).write('complete_task',id,item.text('projectId'),{},item.version,const Uuid().v4());
    } catch (error,stack) { state = AsyncError(error,stack); }
    finally { _writing = false; }
  }
  Future<bool> comment(String body) async {
    if (_writing || body.trim().isEmpty || body.length > 2000) return false;
    _writing = true;
    try {
      await ref.read(tasksRepositoryProvider).write('create_comment',_commentKey,id,{'body':body.trim()},null,_commentKey);
      _commentKey = const Uuid().v4();
      return true;
    } finally { _writing = false; }
  }
  Future<void> delete(String id) => ref.read(commentsRepositoryProvider).delete(id);
}

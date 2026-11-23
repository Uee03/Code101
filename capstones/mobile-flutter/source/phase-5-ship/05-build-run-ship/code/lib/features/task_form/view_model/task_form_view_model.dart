import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../app/providers.dart';
import '../../../core/api_problem.dart';
import '../../../data/models/item.dart';
import '../../../l10n/strings.dart';

typedef FormKey = ({String projectId,String taskId});
final formViewModelProvider = NotifierProvider.autoDispose.family<TaskFormViewModel,TaskFormState,FormKey>(TaskFormViewModel.new);
final class TaskFormState {
  const TaskFormState({this.values = const {},this.fields = const {},this.busy = true,this.error,this.conflict,this.revision = 0});
  final Map<String,Object?> values;
  final Map<String,String> fields;
  final bool busy;
  final Object? error;
  final Item? conflict;
  final int revision;
}
class TaskFormViewModel extends Notifier<TaskFormState> {
  TaskFormViewModel(this.key);
  final FormKey key;
  final String idempotencyKey = const Uuid().v4();
  Item? original;
  Map<String,Object?> _patch = {};
  @override
  TaskFormState build() {
    Future.microtask(_load);
    return const TaskFormState();
  }
  Future<void> _load() async {
    try {
      if (key.taskId.isNotEmpty) {
        original = await ref.read(storeProvider).item('tasks',key.taskId);
        if (original == null) { await ref.read(tasksRepositoryProvider).refreshTask(key.taskId); original = await ref.read(storeProvider).item('tasks',key.taskId); }
      }
      if (key.taskId.isNotEmpty && original == null) throw StateError('not-found');
      state = TaskFormState(busy:false,revision:1,fields:Map<String,String>.from(original?.json['fieldErrors'] as Map? ?? {}),values: Map.unmodifiable({
        'title':'','description':'','status':'todo','priority':'medium','assigneeId':null,'dueDate':null,
        if (original != null) for (final field in const ['title','description','status','priority','assigneeId','dueDate']) field: original!.json[field],
      }));
    } catch (error) { state = TaskFormState(busy:false,error:error); }
  }
  void change(String field,Object? value) {
    state = TaskFormState(values: Map.unmodifiable({...state.values,field:value}),fields:state.fields,busy:false,revision:state.revision);
  }
  String? _validate() {
    final v = state.values;
    final title = (v['title'] as String? ?? '').trim();
    if (title.isEmpty || title.length > 200 || (v['description'] as String? ?? '').length > 10000) return 'validationError';
    final due = v['dueDate'] as String?;
    if (due != null && (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(due) || DateTime.tryParse(due)?.toIso8601String().substring(0,10) != due)) return 'validationError';
    final assignee = v['assigneeId'] as String?;
    if (assignee != null && !RegExp(r'^[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}$').hasMatch(assignee)) return 'validationError';
    return null;
  }
  Future<bool> save() async {
    if (state.busy) return false;
    final invalid = _validate();
    if (invalid != null) { state = TaskFormState(values:state.values,busy:false,fields:{'/title':Strings.text(invalid)}); return false; }
    final values = {...state.values,'title':(state.values['title'] as String).trim()};
    _patch = original == null ? values : {for (final e in values.entries) if (e.value != original!.json[e.key]) e.key:e.value};
    if (_patch.isEmpty) return true;
    return _send(_patch,original?.version);
  }
  Future<bool> _send(Map<String,Object?> patch,int? version) async {
    state = TaskFormState(values:state.values,busy:true);
    try {
      await ref.read(tasksRepositoryProvider).write(original == null ? 'create_task':'update_task',
        original?.id ?? idempotencyKey,original?.text('projectId') ?? key.projectId,patch,version,idempotencyKey);
      state = TaskFormState(values:state.values,busy:false);
      return true;
    } on ApiProblem catch (problem) {
      Item? latest;
      if (problem.status == 412) { await ref.read(tasksRepositoryProvider).refreshTask(key.taskId); latest = await ref.read(storeProvider).item('tasks',key.taskId); }
      state = TaskFormState(values:state.values,busy:false,error:problem,fields:problem.fields,conflict:latest);
      return false;
    } catch (error) { state = TaskFormState(values:state.values,busy:false,error:error); return false; }
  }
  Map<String,Object?> get changed => Map.unmodifiable(_patch);
  Future<bool> resolve(Set<String> keep) async {
    final latest = state.conflict!;
    original = latest;
    final patch = {for (final e in _patch.entries) if (keep.contains(e.key)) e.key:e.value};
    if (patch.isEmpty) return true;
    return _send(patch,latest.version);
  }
}

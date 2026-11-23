import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api_problem.dart';
import '../../../core/format_value.dart';
import '../../../core/widgets/app_frame.dart';
import '../../../core/widgets/collection_panel.dart';
import '../../../l10n/strings.dart';
import '../view_model/task_detail_view_model.dart';
import '../view_model/comments_view_model.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  const TaskDetailScreen(this.id,{super.key});
  final String id;
  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}
class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  final _comment = TextEditingController();
  String? _error;
  @override
  void dispose() { _comment.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(detailViewModelProvider(widget.id));
    final vm = ref.read(detailViewModelProvider(widget.id).notifier);
    final comments = ref.watch(commentsViewModelProvider(widget.id));
    final commentsVm = ref.read(commentsViewModelProvider(widget.id).notifier);
    return AppFrame(title: Strings.text('taskDetail'),child: detail.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error,_) => Center(child: Text(error is ApiProblem ? error.message : Strings.text('networkError'))),
      data: (item) => item == null ? Center(child: Text(Strings.text('empty'))) : ListView(padding: const EdgeInsets.all(16),children: [
        if (item.pending) Text(Strings.text('waiting')),
        for (final key in const ['id','projectId','title','description','status','priority','assigneeId','dueDate','completedAt','createdBy','version','createdAt','updatedAt'])
          ListTile(title: Text(Strings.text(key)),subtitle: Text(formatValue(key,item.json[key]))),
        Wrap(spacing: 8,children: [
          FilledButton(onPressed: vm.complete,child: Text(Strings.text('complete'))),
          OutlinedButton(onPressed: () => context.push('/tasks/${item.id}/edit'),child: Text(Strings.text('edit'))),
        ]),
        Text(Strings.text('comments'),style: Theme.of(context).textTheme.titleLarge),
        // Comments use a shrink-wrapped panel to avoid nested infinite height.
        SizedBox(height: MediaQuery.sizeOf(context).height * .45,child: CollectionPanel(
          state: comments,refresh: commentsVm.refresh,more: () => commentsVm.refresh(next:true),
          tile: (comment) => ListTile(title: Text(comment.label),subtitle: Text(formatValue('createdAt',comment.json['createdAt'])),
            trailing: (comment.json['author'] as Map?)?['id'] == vm.callerId ? TextButton(
              onPressed: () async {
                try { await vm.delete(comment.id); } catch (_) { if (mounted) setState(() => _error = Strings.text('networkError')); }
              },child: Text(Strings.text('delete'))) : null))),
        TextField(controller: _comment,maxLength: 2000,maxLines: null,decoration: InputDecoration(labelText: Strings.text('body'))),
        if (_error != null) Text(_error!),
        FilledButton(onPressed: () async {
          try {
            if (await vm.comment(_comment.text)) { _comment.clear(); await commentsVm.refresh(); }
          } catch (error) { if (mounted) setState(() => _error = error is ApiProblem ? error.message : Strings.text('networkError')); }
        },child: Text(Strings.text('addComment'))),
      ]),
    ));
  }
}

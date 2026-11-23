import '../../../core/widgets/art_icon.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api_problem.dart';
import '../../../core/widgets/app_frame.dart';
import '../../../l10n/strings.dart';
import '../view_model/task_form_view_model.dart';
import 'conflict_sheet.dart';

class TaskFormScreen extends ConsumerWidget {
  const TaskFormScreen({super.key,this.projectId = '',this.taskId = ''});
  final String projectId;
  final String taskId;
  @override
  Widget build(BuildContext context,WidgetRef ref) {
    final provider = formViewModelProvider((projectId:projectId,taskId:taskId));
    final state = ref.watch(provider);
    final vm = ref.read(provider.notifier);
    return AppFrame(title:Strings.text('taskForm'),child: ListView(padding: const EdgeInsets.all(16),children: [
      if (state.busy) const LinearProgressIndicator(),
      if (state.error != null) Text(state.error is ApiProblem ? (state.error as ApiProblem).message : Strings.text('networkError')),
      for (final field in const ['title','description','assigneeId','dueDate'])
        TextFormField(key: ValueKey('$taskId$field${state.revision}'),initialValue: state.values[field] as String? ?? '',
          enabled: !state.busy,maxLines: field == 'description' ? null : 1,
          maxLength: field == 'title' ? 200 : field == 'description' ? 10000 : null,
          decoration: InputDecoration(labelText: Strings.text(field),errorText:state.fields['/$field']),
          onChanged: (value) => vm.change(field,(field == 'dueDate' || field == 'assigneeId') && value.isEmpty ? null : value)),
      for (final field in const ['status','priority'])
        DropdownButtonFormField<String>(icon:ArtIcon('list',Strings.text('status')),key:ValueKey('$field${state.revision}'),initialValue: state.values[field] as String? ?? (field == 'status' ? 'todo':'medium'),
          decoration: InputDecoration(labelText:Strings.text(field),errorText:state.fields['/$field']),
          items: [for (final value in field == 'status' ? const ['todo','in_progress','blocked','done','cancelled'] : const ['low','medium','high','urgent'])
            DropdownMenuItem(value:value,child:Text(Strings.text(value)))],
          onChanged: state.busy ? null : (value) => vm.change(field,value)),
      FilledButton(onPressed: state.busy ? null : () async {
        var saved = await vm.save();
        if (!context.mounted) return;
        final conflict = ref.read(provider).conflict;
        if (!saved && conflict != null) {
          final keep = await showConflict(context,vm.changed,conflict);
          if (keep != null) saved = await vm.resolve(keep);
        }
        if (saved && context.mounted) { if (context.canPop()) { context.pop(); } else { context.go('/teams'); } }
      },child:Text(Strings.text('save'))),
    ]));
  }
}

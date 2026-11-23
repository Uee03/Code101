import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_frame.dart';
import '../../../core/widgets/art_icon.dart';
import '../../../core/widgets/collection_panel.dart';
import '../../../data/models/item.dart';
import '../../../l10n/strings.dart';
import '../view_model/tasks_view_model.dart';

class TasksScreen extends ConsumerWidget {
  const TasksScreen(this.projectId,{super.key});
  final String projectId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = tasksViewModelProvider(projectId);
    final state = ref.watch(provider);
    final vm = ref.read(provider.notifier);
    return AppFrame(title: Strings.text('tasks'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async { await context.push('/projects/$projectId/tasks/new'); await vm.refresh(); },
        icon: ArtIcon('plus',Strings.text('newTask')),label: Text(Strings.text('newTask'))),
      child: Column(children: [
        Padding(padding: const EdgeInsets.all(8),child: Wrap(spacing: 8,children: [
          for (final status in const ['todo','in_progress','blocked','done','cancelled'])
            FilterChip(label: Text(Strings.text(status)),selected: vm.query.statuses.split(',').contains(status),
              onSelected: (selected) {
                final statuses = vm.query.statuses.split(',').where((s) => s.isNotEmpty).toSet();
                if (selected) { statuses.add(status); } else { statuses.remove(status); }
                vm.load(query('tasks',parent: projectId,statuses: (statuses.toList()..sort()).join(','),sort: vm.query.sort));
              }),
        ])),
        DropdownButtonFormField<String>(icon:ArtIcon('list',Strings.text('sort')),initialValue: vm.query.sort,
          decoration: InputDecoration(labelText: Strings.text('sort')),
          items: [for (final entry in const {'-createdAt':'-createdAt','createdAt':'createdAtSort','dueDate':'dueDateSort'}.entries)
            DropdownMenuItem(value: entry.key,child: Text(Strings.text(entry.value)))],
          onChanged: (value) { if (value != null) vm.load(query('tasks',parent: projectId,statuses: vm.query.statuses,sort:value)); }),
        Expanded(child: CollectionPanel(state: state,refresh: vm.refresh,more: () => vm.refresh(next:true),
          tile: (item) => ListTile(title: Text(item.label),
            subtitle: Text('${Strings.text(item.text('status'))} ? ${Strings.text(item.text('priority'))}${item.pending ? ' ? ${Strings.text('waiting')}' : ''}'),
            onTap: () => context.push('/tasks/${item.id}')))),
      ]));
  }
}

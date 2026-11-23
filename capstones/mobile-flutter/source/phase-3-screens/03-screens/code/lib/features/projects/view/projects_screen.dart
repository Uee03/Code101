import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_frame.dart';
import '../../../core/widgets/collection_panel.dart';
import '../../../data/models/item.dart';
import '../../../l10n/strings.dart';
import '../view_model/projects_view_model.dart';

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen(this.teamId,{super.key});
  final String teamId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = projectsViewModelProvider(teamId);
    final state = ref.watch(provider);
    final vm = ref.read(provider.notifier);
    return AppFrame(title: Strings.text('projects'),child: Column(children: [
      SwitchListTile(title: Text(Strings.text('archived')),value: vm.query.archived,
        onChanged: (value) => vm.load(query('projects',parent: teamId,archived: value))),
      Expanded(child: CollectionPanel(state: state,refresh: vm.refresh,more: () => vm.refresh(next:true),
        tile: (item) => ListTile(title: Text('${item.text('key')} ${item.label}'),subtitle: Text(item.text('description')),
          onTap: () => context.push('/projects/${item.id}/tasks')))),
    ]));
  }
}

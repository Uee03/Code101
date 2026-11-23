import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_frame.dart';
import '../../../core/widgets/collection_panel.dart';
import '../../../data/models/item.dart';
import '../../../l10n/strings.dart';
import '../view_model/teams_view_model.dart';

class TeamsScreen extends ConsumerWidget {
  const TeamsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = teamsViewModelProvider('');
    final state = ref.watch(provider);
    final vm = ref.read(provider.notifier);
    return AppFrame(title: Strings.text('teams'),child: Column(children: [
      Padding(padding: const EdgeInsets.all(16),child: TextField(
        decoration: InputDecoration(labelText: Strings.text('search')),
        onSubmitted: (value) => vm.load(query('teams',search: value)))),
      Expanded(child: CollectionPanel(state: state,refresh: vm.refresh,more: () => vm.refresh(next:true),
        tile: (item) => ListTile(title: Text(item.label),subtitle: Text(item.text('description')),
          onTap: () => context.push('/teams/${item.id}/projects')))),
    ]));
  }
}

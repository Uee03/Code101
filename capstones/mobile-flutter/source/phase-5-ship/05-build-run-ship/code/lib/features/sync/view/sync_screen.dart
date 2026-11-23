import 'dart:convert';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_frame.dart';
import '../../../data/models/item.dart';
import '../../../l10n/strings.dart';
import '../../task_form/view/conflict_sheet.dart';
import '../view_model/sync_view_model.dart';

class SyncScreen extends ConsumerWidget {
  const SyncScreen({super.key});
  @override
  Widget build(BuildContext context,WidgetRef ref) {
    final state = ref.watch(syncViewModelProvider);
    final vm = ref.read(syncViewModelProvider.notifier);
    return AppFrame(title:Strings.text('syncQueue'),child:ListView(padding:const EdgeInsets.all(16),children: [
      if (state.busy) const LinearProgressIndicator(),
      if (state.rows.isEmpty) Text(Strings.text('empty')),
      for (final row in state.rows) Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children: [
        Text('${Strings.text(row.kind)} ? ${Strings.text(row.state)}'),
        Text(row.entity),
        if (row.problem != null) Text((jsonDecode(row.problem!) as Map)['title'] as String? ?? Strings.text('networkError')),
        Wrap(spacing:8,children: [
          if (row.state == 'failed' && row.kind != 'create_comment') TextButton(onPressed:() => context.push('/tasks/${row.entity}/edit'),child:Text(Strings.text('edit'))),
          if (row.state != 'conflict') TextButton(onPressed:state.busy ? null : () => vm.retry(row),child:Text(Strings.text('retry'))),
          if (row.state == 'conflict' && row.server != null) TextButton(onPressed:state.busy ? null : () async {
            final theirs = Item(Map<String,Object?>.from(jsonDecode(row.server!) as Map));
            final keep = await showConflict(context,row.body,theirs);
            if (keep != null) await vm.resolve(row,keep);
          },child:Text(Strings.text('conflict'))),
          TextButton(onPressed:state.busy ? null : () => vm.discard(row),child:Text(Strings.text('discardChain'))),
        ]),
      ]))),
    ]));
  }
}

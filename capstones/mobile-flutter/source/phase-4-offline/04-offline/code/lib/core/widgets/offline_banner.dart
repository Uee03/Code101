import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/sync/view_model/sync_view_model.dart';
import '../../l10n/strings.dart';
import '../format_value.dart';
import 'art_icon.dart';

class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});
  @override
  Widget build(BuildContext context,WidgetRef ref) {
    final state = ref.watch(syncViewModelProvider);
    if (state.online && state.rows.isEmpty) return const SizedBox.shrink();
    final message = '${Strings.text(state.online ? 'pending' : 'offline')}: ${formatValue('count',state.rows.length)}';
    return Semantics(liveRegion:true,container:true,child: Material(
      color:Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(padding:const EdgeInsets.all(8),child:Wrap(crossAxisAlignment:WrapCrossAlignment.center,spacing:8,children: [
        ArtIcon('wifi-off',Strings.text('offline')),Text(message),
        TextButton(onPressed:state.busy ? null : ref.read(syncViewModelProvider.notifier).sync,child:Text(Strings.text('syncNow'))),
        TextButton(onPressed:() => context.push('/settings/sync'),child:Text(Strings.text('syncQueue'))),
      ])),
    ));
  }
}

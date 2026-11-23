import '../../../core/widgets/art_icon.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api_problem.dart';
import '../../../core/config.dart';
import '../../../core/widgets/app_frame.dart';
import '../../../l10n/strings.dart';
import '../view_model/settings_view_model.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}
class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _url = TextEditingController(text:Config.apiBase);
  String _backend = 'Python';
  bool _delete = false;
  @override
  void dispose() { _url.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settingsViewModelProvider);
    final vm = ref.read(settingsViewModelProvider.notifier);
    final account = state.value?['account'] as Map?;
    final health = state.value?['health'] as Map?;
    return AppFrame(title:Strings.text('settings'),child:ListView(padding: const EdgeInsets.all(16),children: [
      if (state.isLoading) const LinearProgressIndicator(),
      if (state.hasError) Text(state.error is ApiProblem ? (state.error as ApiProblem).message : Strings.text('queueNotEmpty')),
      DropdownButtonFormField<String>(icon:ArtIcon('list',Strings.text('backend')),initialValue:_backend,decoration:InputDecoration(labelText:Strings.text('backend')),
        items: [for (final name in const ['ASP.NET','Python','Go','customUrl']) DropdownMenuItem(value:name,child:Text(name == 'customUrl' ? Strings.text(name) : name))],
        onChanged: (value) => setState(() { _backend = value!; if (value != 'customUrl') _url.text = Config.apiBase; })),
      TextField(controller:_url,decoration:InputDecoration(labelText:Strings.text('customUrl'))),
      FilledButton(onPressed:state.isLoading ? null : () => vm.select(_backend,_url.text),child:Text(Strings.text('apply'))),
      OutlinedButton(onPressed:state.isLoading ? null : vm.test,child:Text(Strings.text('testConnection'))),
      if (health != null) ListTile(title:Text(Strings.text('health')),subtitle:Text(health.toString())),
      if (account != null) ...[
        ListTile(title:Text(Strings.text('name')),subtitle:Text(account['displayName']?.toString() ?? '')),
        for (final key in const ['roles','scopes']) ListTile(title:Text(Strings.text(key)),subtitle:Text((account[key] as List).join(', '))),
      ],
      TextButton(onPressed: () => context.push('/settings/sync'),child:Text(Strings.text('syncQueue'))),
      CheckboxListTile(value:_delete,onChanged:(value) => setState(() => _delete = value!),title:Text(Strings.text('deleteOffline'))),
      FilledButton(onPressed:state.isLoading ? null : () => vm.signOut(_delete),child:Text(Strings.text('signOut'))),
    ]));
  }
}

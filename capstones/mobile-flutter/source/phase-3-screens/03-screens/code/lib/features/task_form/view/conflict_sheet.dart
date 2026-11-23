import 'package:material_ui/material_ui.dart';
import '../../../core/format_value.dart';
import '../../../data/models/item.dart';
import '../../../l10n/strings.dart';

Future<Set<String>?> showConflict(BuildContext context,Map<String,Object?> mine,Item theirs) =>
  showModalBottomSheet<Set<String>>(context: context,isScrollControlled:true,useSafeArea:true,
    builder: (_) => ConflictSheet(mine,theirs));
class ConflictSheet extends StatefulWidget {
  const ConflictSheet(this.mine,this.theirs,{super.key});
  final Map<String,Object?> mine;
  final Item theirs;
  @override
  State<ConflictSheet> createState() => _ConflictSheetState();
}
class _ConflictSheetState extends State<ConflictSheet> {
  late final _keep = widget.mine.keys.toSet();
  @override
  Widget build(BuildContext context) => SingleChildScrollView(padding: const EdgeInsets.all(24),child: Column(mainAxisSize: MainAxisSize.min,children: [
    Text(Strings.text('conflict'),style: Theme.of(context).textTheme.headlineSmall),
    Text(Strings.text('conflictHelp')),
    for (final e in widget.mine.entries) CheckboxListTile(
      title: Text(Strings.text(e.key)),
      subtitle: Text('${Strings.text('mine')}: ${formatValue(e.key,e.value)}\n${Strings.text('theirs')}: ${formatValue(e.key,widget.theirs.json[e.key])}'),
      value: _keep.contains(e.key),onChanged: (value) => setState(() { if (value!) { _keep.add(e.key); } else { _keep.remove(e.key); } })),
    Wrap(spacing: 8,children: [
      FilledButton(onPressed: () => Navigator.pop(context,_keep),child: Text(Strings.text('keepMine'))),
      TextButton(onPressed: () => Navigator.pop(context,<String>{}),child: Text(Strings.text('takeTheirs'))),
    ]),
  ]));
}

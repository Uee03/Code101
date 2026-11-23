import 'package:material_ui/material_ui.dart';
import '../../../core/widgets/app_frame.dart';
import '../../../l10n/strings.dart';

class SyncScreen extends StatelessWidget {
  const SyncScreen({super.key});
  @override
  Widget build(BuildContext context) => AppFrame(title:Strings.text('syncQueue'),
    child: Center(child:Text(Strings.text('queueNextChapter'))));
}

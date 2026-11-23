import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/strings.dart';
import 'router.dart';

class TasksApp extends ConsumerWidget {
  const TasksApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    title: Strings.text('appTitle'), routerConfig: ref.watch(routerProvider),
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    supportedLocales: const [Locale('en')],
    theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff17467c)),
      materialTapTargetSize: MaterialTapTargetSize.padded),
  );
}

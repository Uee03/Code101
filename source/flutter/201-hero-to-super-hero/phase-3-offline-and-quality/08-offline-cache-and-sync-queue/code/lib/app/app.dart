import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'providers.dart';
import 'router.dart';

class TasksApp extends ConsumerWidget {
  const TasksApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keeps the sync engine alive and wired to sign-in and the network.
    ref.watch(syncRunnerProvider);
    return MaterialApp.router(
      title: 'Tasks and Teams',
      routerConfig: ref.watch(routerProvider),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff17467c)),
        materialTapTargetSize: MaterialTapTargetSize.padded,
      ),
    );
  }
}

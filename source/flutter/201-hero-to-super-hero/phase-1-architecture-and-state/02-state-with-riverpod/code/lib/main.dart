import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'app/app.dart';

void main() {
  runApp(
    ProviderScope(
      // Riverpod 3 retries failed providers by default. We show errors and let the user retry.
      retry: (retryCount, error) => null,
      child: const TasksApp(),
    ),
  );
}

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'app/app.dart';
import 'core/config.dart';
import 'core/url_policy.dart';

void main() {
  try {
    UrlPolicy.validate(Config.apiBase, debug: kDebugMode);
  } on FormatException {
    runApp(const ConfigErrorApp());
    return;
  }
  runApp(
    ProviderScope(
      retry: (retryCount, error) => null,
      child: const TasksApp(),
    ),
  );
}

class ConfigErrorApp extends StatelessWidget {
  const ConfigErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'The app is not configured. Start it with '
                '--dart-define-from-file=config/dev.json',
              ),
            ),
          ),
        ),
      ),
    );
  }
}

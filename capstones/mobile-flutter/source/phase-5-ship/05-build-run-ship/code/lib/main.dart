import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'core/config.dart';
import 'core/url_policy.dart';
import 'l10n/strings.dart';
import 'data/sync/sync_worker.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Strings.load();
  try {
    UrlPolicy.validate(Config.apiBase, debug: kDebugMode);
    UrlPolicy.validate(Config.issuer, debug: kDebugMode);
    await registerSyncWorker();
    runApp(const ProviderScope(child: TasksApp()));
  } on FormatException {
    runApp(MaterialApp(home: Scaffold(body: SafeArea(
      child: Center(child: Text(Strings.text('configurationError'))),
    ))));
  }
}

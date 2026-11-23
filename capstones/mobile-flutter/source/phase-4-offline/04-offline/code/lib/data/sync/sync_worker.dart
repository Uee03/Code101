import 'dart:ui';
import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';
import '../../core/config.dart';
import '../local/database.dart';
import '../repositories/auth_repository.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/token_store.dart';
import '../../l10n/strings.dart';
import 'sync_engine.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task,input) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    await Strings.load();
    final db = AppDatabase();
    final store = TokenStore();
    final auth = AuthRepository(AuthService(),store);
    ApiService? api;
    try {
      await auth.restore();
      final session = await store.read();
      if (session == null || await db.setting('owner') != session.subject) return true;
      api = ApiService(await db.setting('base_url') ?? Config.apiBase,auth);
      await SyncEngine(db,api,auth).drain();
      return true;
    } catch (_) { return false; }
    finally { api?.dispose(); await auth.dispose(); await db.close(); }
  });
}
Future<void> registerSyncWorker() async {
  await Workmanager().initialize(callbackDispatcher);
  await Workmanager().registerPeriodicTask('tasks-sync','tasks-sync',
    frequency:const Duration(minutes:15),
    constraints:Constraints(networkType:NetworkType.connected));
}

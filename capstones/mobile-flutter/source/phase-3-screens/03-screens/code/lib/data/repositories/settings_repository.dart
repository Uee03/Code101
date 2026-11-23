import 'package:flutter/foundation.dart';
import '../../core/config.dart';
import '../../core/url_policy.dart';
import '../local/cache_store.dart';
import '../services/api_service.dart';

final class SettingsRepository {
  SettingsRepository(this.store, this.api);
  final CacheStore store;
  final ApiService api;
  Future<void> restore() async => api.setBase(await store.setting('base_url') ?? Config.apiBase);
  Future<void> select(String label, String url) async {
    UrlPolicy.validate(url, debug: kDebugMode);
    if (await store.pendingCount() != 0) throw StateError('queueNotEmpty');
    final owner = await store.setting('owner');
    await store.clear();
    if (owner != null) await store.setSetting('owner',owner);
    await store.setSetting('base_url',url);
    await store.setSetting('backend_label',label);
    api.setBase(url);
  }
  Future<Map<String,Object?>> account() async {
    final me = await api.me();
    await store.setSetting('owner_name',me['displayName'] as String);
    return me;
  }
  Future<Map<String, Object?>> test() async {
    final health = await api.health();
    final me = await account();
    return {'health': health, 'account': me};
  }
}

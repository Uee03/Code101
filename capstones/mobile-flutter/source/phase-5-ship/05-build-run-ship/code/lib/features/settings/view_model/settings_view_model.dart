import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';

final settingsViewModelProvider = AsyncNotifierProvider<SettingsViewModel,Map<String,Object?>>(SettingsViewModel.new);
class SettingsViewModel extends AsyncNotifier<Map<String,Object?>> {
  @override
  Future<Map<String,Object?>> build() async {
    await ref.read(settingsRepositoryProvider).restore();
    return {};
  }
  Future<void> test() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(ref.read(settingsRepositoryProvider).test);
  }
  Future<void> select(String label,String url) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(settingsRepositoryProvider).select(label,url); return <String,Object?>{};
    });
  }
  Future<void> signOut(bool deleteOffline) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authProvider).signOut();
      if (deleteOffline) await ref.read(storeProvider).clear();
      return <String,Object?>{};
    });
  }
}

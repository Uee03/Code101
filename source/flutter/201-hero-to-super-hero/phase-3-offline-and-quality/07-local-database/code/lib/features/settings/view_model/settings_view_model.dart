import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';

/// Calls the unauthenticated /health operation, so it works before sign-in exists.
final connectionTestProvider = FutureProvider.autoDispose<String>((ref) async {
  final health = await ref.watch(apiServiceProvider).health();
  final database = health.database?.value ?? 'not reported';
  return 'API ${health.status.value}, database $database';
});

final settingsViewModelProvider = Provider<SettingsViewModel>(
  SettingsViewModel.new,
);

class SettingsViewModel {
  SettingsViewModel(this._ref);

  final Ref _ref;

  /// Removes every task stored on this phone. The server keeps its copy.
  Future<void> deleteOfflineData() {
    return _ref.read(taskRepositoryProvider).clearLocal();
  }
}

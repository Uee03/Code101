import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_controller.dart';

final loginViewModelProvider = AsyncNotifierProvider<LoginViewModel, void>(
  LoginViewModel.new,
);

/// State of the sign-in button: idle, busy, or failed.
class LoginViewModel extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> signIn() async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(authControllerProvider.notifier).signIn(),
    );
    if (!ref.mounted) {
      return;
    }
    state = result;
  }
}

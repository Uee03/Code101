import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';

final loginViewModelProvider = AsyncNotifierProvider<LoginViewModel, void>(LoginViewModel.new);
class LoginViewModel extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}
  Future<void> signIn() async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(authProvider).signIn());
  }
  Future<void> signOut() async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(authProvider).signOut());
  }
}

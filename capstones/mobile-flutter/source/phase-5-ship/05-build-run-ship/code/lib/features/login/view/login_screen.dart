import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/strings.dart';
import '../view_model/login_view_model.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(loginViewModelProvider);
    return Scaffold(appBar: AppBar(title: Text(Strings.text('login'))),
      body: SafeArea(child: ListView(padding: const EdgeInsets.all(24), children: [
        if (state.isLoading) const LinearProgressIndicator(),
        if (state.hasError) Text(Strings.text('authError')),
        FilledButton(onPressed: state.isLoading ? null :
          ref.read(loginViewModelProvider.notifier).signIn,
          child: Text(Strings.text('signIn'))),
      ])),
    );
  }
}

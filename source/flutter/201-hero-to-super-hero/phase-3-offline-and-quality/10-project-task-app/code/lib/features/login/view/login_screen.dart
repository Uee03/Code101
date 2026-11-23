import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../view_model/login_view_model.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final login = ref.watch(loginViewModelProvider);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Tasks and Teams',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'You sign in in your browser. The app never sees your password.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (login.isLoading)
                  const CircularProgressIndicator(semanticsLabel: 'Signing in')
                else
                  FilledButton(
                    onPressed: () =>
                        ref.read(loginViewModelProvider.notifier).signIn(),
                    child: const Text('Sign in'),
                  ),
                if (login.hasError) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Sign-in did not work. Check your connection and try again.',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

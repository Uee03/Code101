import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../view_model/auth_controller.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                const Text('Sign in to see your tasks.'),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () =>
                      ref.read(authControllerProvider.notifier).signInDemo(),
                  child: const Text('Sign in (demo)'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

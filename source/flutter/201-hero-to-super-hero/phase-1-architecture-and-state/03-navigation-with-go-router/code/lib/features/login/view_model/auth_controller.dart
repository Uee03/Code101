import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AuthStatus { unknown, signedOut, signedIn }

final authControllerProvider = NotifierProvider<AuthController, AuthStatus>(
  AuthController.new,
);

/// Demo version: lesson 06 replaces it with real OIDC sign-in.
class AuthController extends Notifier<AuthStatus> {
  @override
  AuthStatus build() {
    unawaited(_restore());
    return AuthStatus.unknown;
  }

  Future<void> _restore() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!ref.mounted) {
      return;
    }
    state = AuthStatus.signedOut;
  }

  void signInDemo() {
    state = AuthStatus.signedIn;
  }

  void signOut() {
    state = AuthStatus.signedOut;
  }
}

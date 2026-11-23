import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';

enum AuthStatus { unknown, signedOut, signedIn }

final authControllerProvider = NotifierProvider<AuthController, AuthStatus>(
  AuthController.new,
);

class AuthController extends Notifier<AuthStatus> {
  @override
  AuthStatus build() {
    unawaited(_restore());
    return AuthStatus.unknown;
  }

  /// Screen S1: read the stored session, then decide where to go.
  Future<void> _restore() async {
    final found = await ref.read(authRepositoryProvider).restore();
    if (!ref.mounted) {
      return;
    }
    state = found ? AuthStatus.signedIn : AuthStatus.signedOut;
  }

  /// Opens the system browser. Cancelling is not an error: nothing changes.
  Future<void> signIn() async {
    final signedIn = await ref.read(authRepositoryProvider).signIn();
    if (!ref.mounted) {
      return;
    }
    if (signedIn) {
      state = AuthStatus.signedIn;
    }
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    if (!ref.mounted) {
      return;
    }
    state = AuthStatus.signedOut;
  }

  /// Called by the HTTP layer when the session can no longer be refreshed.
  void expire() {
    state = AuthStatus.signedOut;
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/auth_repository.dart';
import '../data/services/auth_service.dart';
import '../data/services/token_store.dart';

final authProvider = Provider<AuthRepository>((ref) {
  final auth = AuthRepository(AuthService(), TokenStore());
  ref.onDispose(auth.dispose);
  return auth;
});

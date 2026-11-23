import 'dart:async';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/login/view/login_screen.dart';
import '../features/login/view_model/login_view_model.dart';
import '../l10n/strings.dart';
import 'providers.dart';

class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(Stream<bool?> stream) { _subscription = stream.listen((_) => notifyListeners()); }
  late final StreamSubscription<bool?> _subscription;
  @override
  void dispose() { _subscription.cancel(); super.dispose(); }
}

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.read(authProvider);
  final refresh = _RouterRefresh(auth.changes);
  final router = GoRouter(initialLocation: '/', refreshListenable: refresh,
    redirect: (context, state) {
      final path = state.uri.path;
      if (auth.signedIn == null) {
        if (path != '/' && path != '/login') auth.intendedRoute = '${state.uri.path}${state.uri.hasQuery ? '?${state.uri.query}' : ''}';
        return path == '/' ? null : '/';
      }
      if (!auth.signedIn! && path != '/login') {
        if (path != '/') auth.intendedRoute = '${state.uri.path}${state.uri.hasQuery ? '?${state.uri.query}' : ''}';
        return '/login';
      }
      if (auth.signedIn! && (path == '/' || path == '/login')) return auth.intendedRoute;
      return null;
    }, routes: [
      GoRoute(path: '/', builder: (_, _) => Scaffold(body: Center(child: Text(Strings.text('sessionCheck'))))),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/teams', builder: (_, _) => const _SignedInScreen()),
    ]);
  ref.onDispose(() { router.dispose(); refresh.dispose(); });
  unawaited(auth.restore());
  return router;
});

class _SignedInScreen extends ConsumerWidget {
  const _SignedInScreen();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(loginViewModelProvider);
    return Scaffold(appBar: AppBar(title: Text(Strings.text('teams'))), body: ListView(children: [
      Text(Strings.text('continueChapter')),
      if (state.hasError) Text(Strings.text('authError')),
      FilledButton(onPressed: state.isLoading ? null : ref.read(loginViewModelProvider.notifier).signOut,
        child: Text(Strings.text('signOut'))),
    ]));
  }
}

import 'dart:async';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/login/view/login_screen.dart';
import '../l10n/strings.dart';
import '../features/teams/view/teams_screen.dart';
import '../features/projects/view/projects_screen.dart';
import '../features/tasks/view/tasks_screen.dart';
import '../features/task_detail/view/task_detail_screen.dart';
import '../features/task_form/view/task_form_screen.dart';
import '../features/settings/view/settings_screen.dart';
import '../features/sync/view/sync_screen.dart';
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
      // S1 Session check, S2 Login are above; S8 Conflict sheet is a modal over S7.
      GoRoute(path: '/teams', builder: (_, _) => const TeamsScreen()), // S3
      GoRoute(path: '/teams/:teamId/projects', builder: (_, s) => ProjectsScreen(s.pathParameters['teamId']!)), // S4
      GoRoute(path: '/projects/:projectId/tasks', builder: (_, s) => TasksScreen(s.pathParameters['projectId']!)), // S5
      GoRoute(path: '/tasks/:taskId', builder: (_, s) => TaskDetailScreen(s.pathParameters['taskId']!)), // S6
      GoRoute(path: '/projects/:projectId/tasks/new', builder: (_, s) => TaskFormScreen(projectId:s.pathParameters['projectId']!)), // S7
      GoRoute(path: '/tasks/:taskId/edit', builder: (_, s) => TaskFormScreen(taskId:s.pathParameters['taskId']!)),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()), // S9
      GoRoute(path: '/settings/sync', builder: (_, _) => const SyncScreen()), // S10
    ]);
  ref.onDispose(() { router.dispose(); refresh.dispose(); });
  unawaited(ref.read(settingsRepositoryProvider).restore().then((_) => auth.restore()));
  return router;
});

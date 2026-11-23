import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../features/login/view/login_screen.dart';
import '../features/login/view/session_check_screen.dart';
import '../features/login/view_model/auth_controller.dart';
import '../features/settings/view/settings_screen.dart';
import '../features/sync/view/sync_screen.dart';
import '../features/task_detail/view/task_detail_screen.dart';
import '../features/tasks/view/tasks_screen.dart';
import 'app_shell.dart';
import 'providers.dart';

String tasksLocation(String projectId) {
  return '/projects/${Uri.encodeComponent(projectId)}/tasks';
}

/// Only allow paths inside this app as a "return to" target.
String? _safeTarget(String? from) {
  if (from == null || !from.startsWith('/') || from.startsWith('//')) {
    return null;
  }
  if (from == '/' || from.startsWith('/login')) {
    return null;
  }
  return from;
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.onDispose(refresh.dispose);
  ref.listen(authControllerProvider, (previous, next) => refresh.value++);

  String? redirect(BuildContext context, GoRouterState state) {
    final status = ref.read(authControllerProvider);
    final path = state.uri.path;
    final intended = state.uri.queryParameters['from'];
    switch (status) {
      case AuthStatus.unknown:
        if (path == '/') {
          return null;
        }
        return Uri(path: '/', queryParameters: {'from': state.uri.toString()})
            .toString();
      case AuthStatus.signedOut:
        if (path == '/login') {
          return null;
        }
        final target = _safeTarget(intended ?? state.uri.toString());
        return Uri(
          path: '/login',
          queryParameters: {if (target != null) 'from': target},
        ).toString();
      case AuthStatus.signedIn:
        if (path == '/' || path == '/login') {
          return _safeTarget(intended) ??
              tasksLocation(ref.read(defaultProjectIdProvider));
        }
        return null;
    }
  }

  final router = GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: redirect,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SessionCheckScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/projects/:projectId/tasks',
                builder: (context, state) => TasksScreen(
                  projectId: state.pathParameters['projectId']!,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
                routes: [
                  GoRoute(
                    path: 'sync',
                    builder: (context, state) => const SyncScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/tasks/:taskId',
        builder: (context, state) => TaskDetailScreen(
          taskId: state.pathParameters['taskId']!,
        ),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

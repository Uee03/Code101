import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/widgets/refresh_status.dart';
import '../view_model/teams_view_model.dart';

class TeamsScreen extends ConsumerWidget {
  const TeamsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teams = ref.watch(teamsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Teams')),
      body: Column(
        children: [
          RefreshStatus(
            refresh: teamsRefreshProvider,
            onRetry: () => ref.invalidate(teamsRefreshProvider),
          ),
          Expanded(
            child: teams.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => const Center(
                child: Text('The saved teams could not be read.'),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return EmptyMessage(
                    refresh: teamsRefreshProvider,
                    text: 'You are not in a team yet.',
                  );
                }
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final team = items[index];
                    final members = team.memberCount == 1
                        ? '1 member'
                        : '${team.memberCount} members';
                    return ListTile(
                      title: Text(team.name),
                      subtitle: Text(
                        team.description.isEmpty
                            ? members
                            : '$members. ${team.description}',
                      ),
                      onTap: () => context.push(
                        '/teams/${Uri.encodeComponent(team.id)}/projects',
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

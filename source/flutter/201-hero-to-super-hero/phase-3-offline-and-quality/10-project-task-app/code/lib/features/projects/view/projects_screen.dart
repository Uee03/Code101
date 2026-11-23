import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/widgets/refresh_status.dart';
import '../view_model/projects_view_model.dart';

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key, required this.teamId});

  final String teamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectsProvider(teamId));
    final refresh = projectsRefreshProvider(teamId);
    return Scaffold(
      appBar: AppBar(title: const Text('Projects')),
      body: Column(
        children: [
          RefreshStatus(
            refresh: refresh,
            onRetry: () => ref.invalidate(refresh),
          ),
          Expanded(
            child: projects.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => const Center(
                child: Text('The saved projects could not be read.'),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return EmptyMessage(
                    refresh: refresh,
                    text: 'This team has no projects yet.',
                  );
                }
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final project = items[index];
                    return ListTile(
                      title: Text('${project.key}: ${project.name}'),
                      subtitle: Text(
                        project.description.isEmpty
                            ? 'No description'
                            : project.description,
                      ),
                      onTap: () => context.push(
                        '/projects/${Uri.encodeComponent(project.id)}/tasks',
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

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/result.dart';
import '../../../data/models/project.dart';

final projectsProvider =
    StreamProvider.autoDispose.family<List<Project>, String>(
  (ref, teamId) => ref.watch(projectRepositoryProvider).watchProjects(teamId),
);

final projectsRefreshProvider = FutureProvider.autoDispose.family<void, String>((
  ref,
  teamId,
) async {
  final result = await ref.watch(projectRepositoryProvider).refresh(teamId);
  if (result case Err(error: final failure)) {
    throw failure;
  }
});

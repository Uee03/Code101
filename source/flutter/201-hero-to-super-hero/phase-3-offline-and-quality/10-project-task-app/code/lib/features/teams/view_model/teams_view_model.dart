import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/result.dart';
import '../../../data/models/team.dart';

final teamsProvider = StreamProvider.autoDispose<List<Team>>(
  (ref) => ref.watch(teamRepositoryProvider).watchTeams(),
);

final teamsRefreshProvider = FutureProvider.autoDispose<void>((ref) async {
  final result = await ref.watch(teamRepositoryProvider).refresh();
  if (result case Err(error: final failure)) {
    throw failure;
  }
});

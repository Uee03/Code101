import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../core/collection_view_model.dart';
import '../../../data/models/item.dart';
import '../../../data/repositories/collection_repository.dart';

final teamsViewModelProvider = NotifierProvider.family<TeamsViewModel, CollectionState, String>(TeamsViewModel.new);
class TeamsViewModel extends CollectionViewModel {
  TeamsViewModel(String parent) : super(query('teams',parent: parent));
  @override
  CollectionRepository get repository => ref.read(teamsRepositoryProvider);
}

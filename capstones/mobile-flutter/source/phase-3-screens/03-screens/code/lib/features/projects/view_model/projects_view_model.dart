import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../core/collection_view_model.dart';
import '../../../data/models/item.dart';
import '../../../data/repositories/collection_repository.dart';

final projectsViewModelProvider = NotifierProvider.family<ProjectsViewModel, CollectionState, String>(ProjectsViewModel.new);
class ProjectsViewModel extends CollectionViewModel {
  ProjectsViewModel(String parent) : super(query('projects',parent: parent));
  @override
  CollectionRepository get repository => ref.read(projectsRepositoryProvider);
}

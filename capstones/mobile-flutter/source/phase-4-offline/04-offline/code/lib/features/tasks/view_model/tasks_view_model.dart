import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../core/collection_view_model.dart';
import '../../../data/models/item.dart';
import '../../../data/repositories/collection_repository.dart';

final tasksViewModelProvider = NotifierProvider.family<TasksViewModel, CollectionState, String>(TasksViewModel.new);
class TasksViewModel extends CollectionViewModel {
  TasksViewModel(String parent) : super(query('tasks',parent: parent));
  @override
  CollectionRepository get repository => ref.read(tasksRepositoryProvider);
}

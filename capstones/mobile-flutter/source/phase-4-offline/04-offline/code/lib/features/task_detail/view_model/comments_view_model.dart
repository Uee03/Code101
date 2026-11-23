import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../core/collection_view_model.dart';
import '../../../data/models/item.dart';
import '../../../data/repositories/collection_repository.dart';

final commentsViewModelProvider = NotifierProvider.family<CommentsViewModel, CollectionState, String>(CommentsViewModel.new);
class CommentsViewModel extends CollectionViewModel {
  CommentsViewModel(String parent) : super(query('comments',parent: parent));
  @override
  CollectionRepository get repository => ref.read(commentsRepositoryProvider);
}

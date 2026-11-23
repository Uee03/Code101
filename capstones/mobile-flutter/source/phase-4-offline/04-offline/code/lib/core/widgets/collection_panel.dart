import 'package:material_ui/material_ui.dart';
import '../../l10n/strings.dart';
import '../../data/models/item.dart';
import '../api_problem.dart';
import '../collection_view_model.dart';

class CollectionPanel extends StatelessWidget {
  const CollectionPanel({super.key,required this.state,required this.refresh,required this.more,required this.tile});
  final CollectionState state;
  final Future<void> Function() refresh;
  final Future<void> Function() more;
  final Widget Function(Item) tile;
  @override
  Widget build(BuildContext context) => RefreshIndicator(onRefresh: refresh,
    child: NotificationListener<ScrollEndNotification>(onNotification: (event) {
      if (event.metrics.extentAfter < 160) more();
      return false;
    }, child: ListView(physics: const AlwaysScrollableScrollPhysics(),padding: const EdgeInsets.all(16),children: [
      if (state.loading) const LinearProgressIndicator(),
      if (state.error != null) Text(state.error is ApiProblem ? (state.error as ApiProblem).message : Strings.text('networkError')),
      if (!state.loading && (state.page?.items.isEmpty ?? true)) Text(Strings.text('empty')),
      for (final item in state.page?.items ?? <Item>[]) tile(item),
      if (state.page?.cursor != null) TextButton(onPressed: state.loading ? null : more,child: Text(Strings.text('loadMore'))),
    ])),
  );
}

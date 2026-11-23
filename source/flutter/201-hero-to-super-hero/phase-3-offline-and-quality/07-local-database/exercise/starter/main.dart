// Exercise 07: a cache that tells its listeners. Run with: dart run main.dart
import 'dart:async';

class Item {
  const Item(this.id, this.title, {this.synced = true});

  final String id;
  final String title;

  /// false means the item was created here and has not reached the server yet.
  final bool synced;
}

class MemoryCache {
  final Map<String, Item> _rows = {};
  final StreamController<void> _changes = StreamController<void>.broadcast();

  /// Emits the current titles at once and again after every change.
  Stream<List<String>> watch() {
    return Stream<List<String>>.multi((controller) {
      controller.add(_titles());
      final subscription = _changes.stream.listen(
        (_) => controller.add(_titles()),
      );
      controller.onCancel = subscription.cancel;
    });
  }

  void addPending(Item item) {
    _rows[item.id] = item;
    _changes.add(null);
  }

  void replaceSynced(List<Item> fromServer) {
    // TODO: the server owns only the synced items.
    //       1. Remember the ids of the items that are NOT synced.
    //       2. Remove the synced items (removeWhere).
    //       3. Add every server item whose id is not in the remembered set.
    _rows.clear();
    for (final item in fromServer) {
      _rows[item.id] = item;
    }
    _changes.add(null);
  }

  List<String> _titles() => [for (final item in _rows.values) item.title];
}

Future<void> tick() => Future<void>.delayed(Duration.zero);

Future<void> main() async {
  final cache = MemoryCache();
  cache.watch().listen((titles) => print('screen: $titles'));
  await tick();
  cache.replaceSynced(const [Item('1', 'Write report'), Item('2', 'Book room')]);
  await tick();
  cache.addPending(const Item('local-1', 'Buy cable', synced: false));
  await tick();
  cache.replaceSynced(const [Item('1', 'Write report'), Item('3', 'Call Sam')]);
  await tick();
}

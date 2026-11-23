// Exercise 06: one refresh for many callers. Run with: dart run main.dart

class TokenSource {
  int refreshCalls = 0;
  Future<String>? _inFlight;

  Future<String> token() {
    // TODO: when a refresh is already running, return that same Future.
    //       Otherwise start _refresh(), remember it in _inFlight and set _inFlight
    //       back to null when it finishes (use whenComplete).
    return _refresh();
  }

  Future<String> _refresh() async {
    refreshCalls++;
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return 'new-$refreshCalls';
  }
}

Future<void> main() async {
  final source = TokenSource();
  final results = await Future.wait([
    source.token(),
    source.token(),
    source.token(),
  ]);
  print(results);
  print('refresh calls: ${source.refreshCalls}');
  print(await source.token());
  print('refresh calls: ${source.refreshCalls}');
}

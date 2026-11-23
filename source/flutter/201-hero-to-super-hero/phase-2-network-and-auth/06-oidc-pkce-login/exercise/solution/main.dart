// Exercise 06: one refresh for many callers. Run with: dart run main.dart

class TokenSource {
  int refreshCalls = 0;
  Future<String>? _inFlight;

  Future<String> token() {
    final running = _inFlight;
    if (running != null) {
      return running;
    }
    final started = _refresh().whenComplete(() {
      _inFlight = null;
    });
    _inFlight = started;
    return started;
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

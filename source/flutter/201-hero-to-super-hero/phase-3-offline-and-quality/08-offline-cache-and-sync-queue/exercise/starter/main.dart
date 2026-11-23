// Exercise 08: waiting time between retries. Run with: dart run main.dart

const base = Duration(seconds: 2);
const cap = Duration(minutes: 5);

/// [attempt] is 1 for the first retry. [jitter] is a number from 0 to 1.
Duration delay(int attempt, double jitter, {Duration? retryAfter}) {
  // TODO 1: the ceiling doubles with every attempt: base, 2 x base, 4 x base ...
  //         and never goes above cap.
  // TODO 2: "equal jitter": wait half the ceiling plus jitter x the other half.
  // TODO 3: when retryAfter is longer than the computed wait, return retryAfter.
  return base * (1 << (attempt - 1));
}

void main() {
  for (var attempt = 1; attempt <= 9; attempt++) {
    final shortest = delay(attempt, 0).inSeconds;
    final longest = delay(attempt, 1).inSeconds;
    print('attempt $attempt: ${shortest}s to ${longest}s');
  }
  final server = delay(2, 0, retryAfter: const Duration(seconds: 120));
  print('Retry-After 120s at attempt 2: ${server.inSeconds}s');
  final capped = delay(9, 1, retryAfter: const Duration(seconds: 60));
  print('Retry-After 60s at attempt 9: ${capped.inSeconds}s');
}

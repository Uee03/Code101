import 'dart:math';

/// How long to wait before the next try.
///
/// The ceiling doubles with every attempt (2 s, 4 s, 8 s ...) up to five minutes.
/// "Equal jitter" then picks a time between half the ceiling and the ceiling, so many
/// phones that failed together do not all come back in the same second.
/// [jitter] is a number from 0 to 1 (the caller passes a random one).
/// A server that sent Retry-After is obeyed when its wait is longer.
Duration backoffDelay(
  int attempt,
  double jitter, {
  Duration? retryAfter,
}) {
  const base = Duration(seconds: 2);
  const cap = Duration(minutes: 5);
  final steps = min(max(attempt - 1, 0), 20);
  final doubled = base * (1 << steps);
  final ceiling = doubled > cap ? cap : doubled;
  final half = ceiling ~/ 2;
  final computed = half + half * jitter;
  if (retryAfter != null && retryAfter > computed) {
    return retryAfter;
  }
  return computed;
}

import 'dart:math';
void main() {
  const attempts = 3;
  final delay = min(3600000,1000 * (1 << min(attempts,10)));
  print('Retry in $delay ms (before jitter)');
}

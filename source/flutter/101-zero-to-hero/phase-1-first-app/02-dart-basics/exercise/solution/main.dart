// Exercise 02: tip calculator. Run with: dart run main.dart

double tipAmount(double bill, {double percent = 10}) {
  return bill * percent / 100;
}

String? pickName(bool known) => known ? 'Sam' : null;

void main() {
  final double bill = 80;
  print('Tip (10%): ${tipAmount(bill).toStringAsFixed(2)}');
  print('Tip (15%): ${tipAmount(bill, percent: 15).toStringAsFixed(2)}');
  final String? name = pickName(false);
  print('Table for ${name ?? 'guest'}');
  final double total = bill + tipAmount(bill, percent: 15);
  print('Total with 15% tip: ${total.toStringAsFixed(2)}');
  print('Per person (4): ${(total / 4).toStringAsFixed(2)}');
}

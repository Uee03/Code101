// Exercise 02: tip calculator. Run with: dart run main.dart

double tipAmount(double bill, {double percent = 10}) {
  // TODO 1: return the tip: the bill times percent divided by 100
  return 0;
}

String? pickName(bool known) => known ? 'Sam' : null;

void main() {
  final double bill = 80;
  print('Tip (10%): ${tipAmount(bill).toStringAsFixed(2)}');
  // TODO 2: print the 15% tip in the same format, using the named argument percent
  final String? name = pickName(false);
  // TODO 3: print 'Table for ' followed by the name, or the word guest when there is no name
  // TODO 4: print 'Total with 15% tip: ' followed by the bill plus the 15% tip, 2 decimals
}

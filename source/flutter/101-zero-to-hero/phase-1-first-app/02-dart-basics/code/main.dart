// Lesson 02: Dart basics. Run with: dart run main.dart

const double taxRate = 0.1;

double lineTotal(int quantity, double unitPrice) {
  return quantity * unitPrice;
}

double addTax(double amount, {double rate = taxRate}) => amount * (1 + rate);

String describeCups(int cups) {
  if (cups == 0) {
    return 'no cups';
  } else if (cups == 1) {
    return 'one cup';
  } else {
    return '$cups cups';
  }
}

String greet(String name, [String? nickname]) {
  final shown = nickname ?? name;
  return 'Hello, $shown!';
}

String? findNote(bool hasNote) => hasNote ? 'extra foam' : null;

void main() {
  // Variables and types
  String shop = 'Bean There';
  final String city = 'Lisbon';
  int cups = 3;
  double price = 2.5;
  bool isOpen = true;
  var motto = 'Fresh every hour';

  print('Shop: $shop in $city');
  print('Motto: $motto (${motto.length} characters)');
  print('Open now: $isOpen');

  // Numbers and functions
  double subtotal = lineTotal(cups, price);
  print('Subtotal: ${subtotal.toStringAsFixed(2)}');
  print('With tax: ${addTax(subtotal).toStringAsFixed(2)}');
  print('With 20% tax: ${addTax(subtotal, rate: 0.2).toStringAsFixed(2)}');
  int orders = 10;
  print('${orders ~/ 4} full boxes, ${orders % 4} cups left over');

  // Decisions
  print(describeCups(0));
  print(describeCups(1));
  print(describeCups(cups));
  if (isOpen && cups > 2) {
    print('Big order, shop is open');
  } else {
    print('Small order or closed');
  }

  // Loops
  for (var i = 1; i <= cups; i++) {
    print('Cup $i of $cups');
  }
  var left = cups;
  while (left > 0) {
    left--;
  }
  print('Cups left: $left');

  // Null safety
  String? note = findNote(false);
  print(note ?? 'no note');
  print(note?.length);
  note = findNote(true);
  if (note != null) {
    print('Note has ${note.length} characters');
  }
  print(greet('Maria'));
  print(greet('Maria', 'Mia'));
}

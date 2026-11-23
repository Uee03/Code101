// Exercise 03: a small shop. Run with: dart run main.dart

class Product {
  Product(this.name, this.price);

  final String name;
  final double price;

  // TODO 1: override toString so it returns the name, a colon and the price with 2 decimals
}

Future<double> loadDiscount() async {
  await Future.delayed(const Duration(milliseconds: 100));
  return 0.1;
}

Future<void> main() async {
  final products = [
    Product('Pen', 1.5),
    Product('Book', 12.0),
    Product('Bag', 30.0),
  ];
  // TODO 2: print every product with a for-in loop
  // TODO 3: use where to keep the products cheaper than 20 and print how many there are
  // TODO 4: add up all prices with a loop and print the total
  // TODO 5: await loadDiscount() and print the total after that discount
}

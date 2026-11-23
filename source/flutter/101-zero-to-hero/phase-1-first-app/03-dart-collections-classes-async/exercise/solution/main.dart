// Exercise 03: a small shop. Run with: dart run main.dart

class Product {
  Product(this.name, this.price);

  final String name;
  final double price;

  @override
  String toString() => '$name: ${price.toStringAsFixed(2)}';
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
  for (final product in products) {
    print(product);
  }
  final cheap = products.where((product) => product.price < 20).toList();
  print('Cheap products: ${cheap.length}');
  var total = 0.0;
  for (final product in products) {
    total += product.price;
  }
  print('Total: ${total.toStringAsFixed(2)}');
  final discount = await loadDiscount();
  print('Discounted total: ${(total * (1 - discount)).toStringAsFixed(2)}');
}

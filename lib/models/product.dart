class Product {
  final String name;
  final String description;
  final String image;
  final String price;
  final String phone;
  final String category;

  Product({
    required this.name,
    required this.description,
    required this.image,
    required this.price,
    required this.phone,
    required this.category,
  });

  double get numericPrice {
    return double.tryParse(
      price.replaceAll(RegExp(r'[^0-9,]'), '')
        .replaceAll(',', '.'),
    ) ?? 0.0;
  }
}

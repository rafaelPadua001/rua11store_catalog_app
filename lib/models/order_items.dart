class OrderItem {
  final String description;
  final String name;
  final String? productImage;
  final int quantity;
  final double totalPrice;
  final double unitPrice;

  OrderItem({
    required this.description,
    required this.name,
    this.productImage,
    required this.quantity,
    required this.totalPrice,
    required this.unitPrice,
  });

factory OrderItem.fromJson(Map<String, dynamic> json) {
  return OrderItem(
    description: json['description'],
    name: json['name'],
    quantity: json['quantity'] is int ? json['quantity'] : int.parse(json['quantity'].toString()),
    totalPrice: json['total_price'] is num
        ? (json['total_price'] as num).toDouble()
        : double.parse(json['total_price'].toString()),
    unitPrice: json['unit_price'] is num
        ? (json['unit_price'] as num).toDouble()
        : double.parse(json['unit_price'].toString()),
  );
}



  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'name': name,
      'product_image': productImage,
      'quantity': quantity,
      'total_price': totalPrice,
      'unit_price': unitPrice,
    };
  }
}

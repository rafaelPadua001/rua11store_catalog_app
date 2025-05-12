class OrderItem {
  final int itemId;
  final int productId;
  final String productName;
  final String productImage;
  final String productDescription;
  final String productPrice;
  final int quantity;
  final double totalPrice;
  final double unitPrice;

  OrderItem({
    required this.itemId,
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.productDescription,
    required this.productPrice,
    required this.quantity,
    required this.totalPrice,
    required this.unitPrice,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      itemId: json['item_id'],
      productId: json['product_id'],
      productName: json['product_name'],
      productImage: json['product_image'],
      productDescription: json['product_description'],
      productPrice: json['product_price'],
      quantity: json['quantity'],
      totalPrice: (json['total_price'] as num).toDouble(),
      unitPrice: (json['unit_price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item_id': itemId,
      'product_id': productId,
      'product_name': productName,
      'product_image': productImage,
      'product_description': productDescription,
      'product_price': productPrice,
      'quantity': quantity,
      'total_price': totalPrice,
      'unit_price': unitPrice,
    };
  }
}

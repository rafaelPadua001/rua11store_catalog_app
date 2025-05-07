class CartItem {
  final String id;
  final String userId;
  final int productId;
  final String productName;
  final double price;
  final String description;
  final int quantity;
  final double width;
  final double height;
  final double weight;
  final double length;
  final String imageUrl;
  final String category; // Novo campo
  final DateTime? createdAt;

  CartItem({
    required this.id,
    required this.userId,
    required this.productId,
    required this.productName,
    required this.price,
    required this.description,
    this.quantity = 1,
    required this.width,
    required this.height,
    required this.weight,
    required this.length,
    required this.imageUrl,
    required this.category,
    this.createdAt,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      userId: json['user_id'],
      productId: json['product_id'],
      productName: json['product_name'],
      price: (json['price'] as num).toDouble() / 100,
      description: json['description'],
      quantity: json['quantity'] as int,
      width: (json['width'] as num?)?.toDouble() ?? 0.0,
      height: (json['height'] as num?)?.toDouble() ?? 0.0,
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      length: (json['length'] as num?)?.toDouble() ?? 0.0,
      imageUrl: json['image_url'],
      category: json['category'], // Novo campo
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'product_id': productId,
      'product_name': productName,
      'price': price,
      'description': description,
      'quantity': quantity,
      'width': width,
      'height': height,
      'weight': weight,
      'length': length,
      'image_url': imageUrl,
      'category': category, // Novo campo
    };
  }
}

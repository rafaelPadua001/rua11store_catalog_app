class CartItem {
  final String id;
  final String userId;
  final String productName;
  final double price;
  final String description;
  final int quantity;
  final String imageUrl;
  final String category; // Novo campo
  final DateTime? createdAt;

  CartItem({
    required this.id,
    required this.userId,
    required this.productName,
    required this.price,
    required this.description,
    this.quantity = 1,
    required this.imageUrl,
    required this.category,
    this.createdAt,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      userId: json['user_id'],
      productName: json['product_name'],
      price: (json['price'] as num).toDouble(),
      description: json['description'],
      quantity: json['quantity'] as int,
      imageUrl: json['image_url'],
      category: json['category'], // Novo campo
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'product_name': productName,
      'price': price,
      'description': description,
      'quantity': quantity,
      'image_url': imageUrl,
      'category': category, // Novo campo
    };
  }
}
class Product {
  final int id;
  final String name;
  final String description;
  final String image;
  final int quantity;
  final String price;
  final String phone;
  final int categoryId;
  final int? subcategoryId;
  final int? parentId; // Novo campo adicionado!
  final int userId;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.image,
    required this.quantity,
    required this.price,
    required this.phone,
    required this.categoryId,
    required this.subcategoryId,
    required this.parentId, // Novo campo incluído no construtor!
    required this.userId,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Nome não disponível',
      description: json['description'] ?? 'Sem descrição',
      image: json['image_path'] ?? 'assets/images/default.png',
      quantity: json['quantity'] ?? 0,
      price: json['price'] != null ? json['price'].toString() : '0',
      phone: json['phone'] ?? 'Sem telefone',
      categoryId: json['category_id'] ?? 0,
      subcategoryId:
          json['subcategory_id'] as int?, // Tratamento seguro para null
      parentId: json['parent_id'] as int?, // Garantia de que pode ser null
      userId: json['user_id'] ?? 0,
    );
  }


  double get numericPrice {
    return double.tryParse(
          price.replaceAll(RegExp(r'[^0-9,]'), '').replaceAll(',', '.'),
        ) ??
        0.0;
  }
}

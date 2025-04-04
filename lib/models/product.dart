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
  final int? parentId;
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
    this.subcategoryId, // Não precisa de `required` pois pode ser `null`
    this.parentId,
    required this.userId,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) ?? 0 : 0,
      name: json['name']?.toString() ?? 'Nome não disponível',
      description: json['description']?.toString() ?? 'Sem descrição',
      image: json['image_path']?.toString() ?? '', // Removido caminho local
      quantity: json['quantity'] != null
          ? int.tryParse(json['quantity'].toString()) ?? 0
          : 0,
      price: json['price']?.toString() ?? '0',
      phone: json['phone']?.toString() ?? 'Sem telefone',
      categoryId: json['category_id'] != null
          ? int.tryParse(json['category_id'].toString()) ?? 0
          : 0,
      subcategoryId: json['subcategory_id'] != null
          ? int.tryParse(json['subcategory_id'].toString())
          : null,
      parentId: json['parent_id'] != null
          ? int.tryParse(json['parent_id'].toString())
          : null,
      userId: json['user_id'] != null
          ? int.tryParse(json['user_id'].toString()) ?? 0
          : 0,
    );
  }

  /// **Conversão segura do preço para `double`**
  double get numericPrice {
    return double.tryParse(
          price.replaceAll(RegExp(r'[^0-9,]'), '').replaceAll(',', '.'),
        ) ??
        0.00;
  }
}

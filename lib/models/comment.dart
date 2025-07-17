class Comment {
  final int id;
  final String comment;
  final int productId;
  final String? userId;
  final String? userName;
  final String? avatar_url;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Comment({
    required this.id,
    required this.comment,
    required this.productId,
    required this.userId,
    this.userName,
    this.avatar_url,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id:
          json['id'] is int
              ? json['id']
              : int.tryParse(json['id'].toString()) ?? 0,
      comment: json['comment']?.toString() ?? '',
      productId:
          json['product_id'] is int
              ? json['product_id']
              : int.tryParse(json['product_id'].toString()) ?? 0,
      userId: json['user_id']?.toString(), // nullable String
      userName: json['user_name']?.toString(),
      avatar_url: json['avatar_url']?.toString(),
      status: json['status']?.toString() ?? 'pendente',
      createdAt:
          json['created_at'] != null
              ? DateTime.tryParse(json['created_at'].toString())
              : null,
      updatedAt:
          json['updated_at'] != null
              ? DateTime.tryParse(json['updated_at'].toString())
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'comment': comment,
      'product_id': productId,
      'user_id': userId,
      'user_name': userName,
      'avatar_url': avatar_url,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

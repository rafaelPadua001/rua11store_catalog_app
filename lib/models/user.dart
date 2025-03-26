class UserModel {
  final String id;
  final String email;
  final DateTime createdAt;
  final String name;
  final int age;
  final String? avatarUrl;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.email,
    required this.createdAt,
    this.name = '',
    this.age = 0,
    this.avatarUrl,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? createdAt;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['user_id'] ?? json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      age: json['age'] ?? 0,
      avatarUrl: json['avatar_url'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': id,
    'email': email,
    'name': name,
    'age': age,
    'avatar_url': avatarUrl,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    int? age,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      age: age ?? this.age,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
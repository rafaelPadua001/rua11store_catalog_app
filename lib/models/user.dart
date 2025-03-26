class UserModel {
  final String id;
  final String userId;
  final String name;
  final String email;
  final int age;
  final String avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.age,
    required this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      name: json['display_name'] ?? '',
      email: json['email'] ?? '',
      age: json['age'] ?? 0,
      avatarUrl: json['avatar_url'] ?? '',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'email': email,
      'age': age,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    int? age,
    String? avatarUrl,
  }) {
    return UserModel(
      id: id,
      userId: userId,
      name: name ?? this.name,
      email: email ?? this.email,
      age: age ?? this.age,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
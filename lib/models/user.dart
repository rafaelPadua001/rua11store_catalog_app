// lib/models/profile_user_model.dart
class UserModel {
  final String imageUrl;
  final String name;
  final String email;
  final int age;

  const UserModel({
    required this.imageUrl,
    required this.name,
    required this.email,
    required this.age,
  });

  // Método para criar um modelo vazio (opcional)
  static UserModel empty() {
    return UserModel(
      imageUrl: '',
      name: '',
      email: '',
      age: 0,
    );
  }

  // Método para converter de/para JSON (opcional)
  Map<String, dynamic> toJson() {
    return {
      'imageUrl': imageUrl,
      'name': name,
      'email': email,
      'age': age,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      imageUrl: json['imageUrl'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      age: json['age'] ?? 0,
    );
  }
}
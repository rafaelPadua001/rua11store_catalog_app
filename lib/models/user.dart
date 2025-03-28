class UserModel {
  final String id;
  final String email;
  final DateTime createdAt;
  final String full_name;
  final DateTime? birthDate;  // Replaced age with birthDate
  final String? avatarUrl;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.email,
    required this.createdAt,
    this.full_name = '',
    this.birthDate,  // Added birthDate
    this.avatarUrl,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? createdAt;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['user_id'] ?? json['id'] ?? '',
      email: json['email'] ?? '',
      full_name: json['full_name'] ?? '',
      birthDate: json['birth_date'] != null 
          ? DateTime.parse(json['birth_date'])
          : null,  // Parse birthDate instead of age
      avatarUrl: json['avatar_url'],
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] ??
            json['created_at'] ??
            DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': id,
    'email': email,
    'full_name': full_name,
    'birth_date': birthDate?.toIso8601String(),  // Replaced age with birth_date
    'avatar_url': avatarUrl,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  UserModel copyWith({
    String? id,
    String? email,
    String? full_name,
    DateTime? birthDate,  // Replaced age with birthDate
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      full_name: full_name ?? this.full_name,
      birthDate: birthDate ?? this.birthDate,  // Updated parameter
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
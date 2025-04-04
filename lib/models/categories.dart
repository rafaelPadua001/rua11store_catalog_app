import 'package:flutter/material.dart';

class Categories {
  final int id;
  final String name;
  // final String image;
  final IconData icon;
  final bool isSubcategory;
  final int? parentId;
  final int userId;
  

  Categories({
    required this.id,
    required this.name,
    required this.isSubcategory,
    required this.parentId,
    required this.userId,
    /* required this.image, */
    required this.icon 
  
    });
    
    factory Categories.fromJson(Map<String, dynamic> json){
      return Categories(
        id: json['id'],
        name: json['name'] ?? '',
        isSubcategory:  json['is_subcategory'] ?? false,
        parentId: json['parentId'],
        userId: json['user_id'],
        icon: _mapNameToIcon(json['name'])
      );
    }

    static IconData _mapNameToIcon(String name){
      final lowerName = name.toLowerCase();
      if (lowerName.contains('sedas')) return Icons.layers;
      if (lowerName.contains('tabacos')) return Icons.smoking_rooms;
      if (lowerName.contains('filtros')) return Icons.filter_alt;
      if (lowerName.contains('piteiras')) return Icons.circle;

      return Icons.category;
      
    }
}
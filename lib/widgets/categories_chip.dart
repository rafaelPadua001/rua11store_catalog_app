import 'package:flutter/material.dart';
import '../models/categories.dart';

class CategoriesChip extends StatelessWidget {
  final Categories categories;
  final VoidCallback onTap;

  const CategoriesChip({
    super.key,
    required this.categories,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Chip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(categories.icon, size: 18, color: Colors.black), // Ícone
            SizedBox(width: 5),
            Text(categories.name),
          ],
        ),
        backgroundColor: Colors.grey[200],
      ),
    );
  }
}

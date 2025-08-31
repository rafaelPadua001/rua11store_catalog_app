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
      child: Theme(
        data: Theme.of(context).copyWith(
          chipTheme: Theme.of(context).chipTheme.copyWith(
            side: BorderSide.none, // mata o contorno vindo do tema
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide.none,
            ),
          ),
        ),
        child: Chip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(categories.icon, size: 18, color: Colors.black),
              SizedBox(width: 5),
              Text(categories.name),
            ],
          ),
          backgroundColor: const Color.fromARGB(255, 197, 197, 197),
          // redundância útil caso sua versão aceite 'side' no Chip:
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

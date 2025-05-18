// AgeCheckDialog.dart
import 'package:flutter/material.dart';

class AgeCheckDialog extends StatelessWidget {
  const AgeCheckDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirmação de Idade'),
      content: const Text('Você tem 18 anos ou mais?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Não', style: TextStyle(color: Colors.red)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Sim'),
        ),
      ],
    );
  }
}

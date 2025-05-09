import 'package:flutter/material.dart';

class ZipcodeInputWidget extends StatelessWidget {
  final TextEditingController zipController;
  final void Function(String) onSearch;

  const ZipcodeInputWidget({
    super.key,
    required this.zipController,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          // Campo de texto (CEP)
          Expanded(
            child: TextField(
              controller: zipController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'CEP',
                hintText: '00000-000',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8), // Espaço entre o input e o botão
          // Botão ao lado
          TextButton(
            onPressed: () {
              final zipcode = zipController.text.trim();
              if (zipcode.isEmpty || zipcode.length < 8) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('CEP inválido')));
                return;
              }
              onSearch(zipcode);
            },
            child: const Text('Buscar'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';

class BottomSheetPage extends StatefulWidget {
  @override
  _BottomSheetState createState() => _BottomSheetState();
}

class _BottomSheetState extends State<BottomSheetPage> {
  final zipController = MaskedTextController(mask: '00000-000');

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          width: MediaQuery.of(context).size.width * 0.9,   
          child: Column(
            mainAxisSize:
                MainAxisSize
                    .min, // importante para ajustar à altura do conteúdo
            children: [
              _buildZipcodeInput(),
              Divider(),
              SizedBox(height: 6),
              _buildCloseButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCloseButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ElevatedButton(
          onPressed: () => {Navigator.pop(context)},
          child: Text('close bottomsheet'),
        ),
      ],
    );
  }

  Widget _buildZipcodeInput() {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Row(
      children: [
        // Campo de texto (CEP)
        Expanded(
          child: TextField(
            controller: zipController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'CEP',
              hintText: '00000-000',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        SizedBox(width: 8), // Espaço entre o input e o botão

        // Botão ao lado
        TextButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Buscar CEP ainda não implementado')),
            );
          },
          child: Text('Buscar'),
        ),
        Divider(),
      ],
    ),
  );
}

}

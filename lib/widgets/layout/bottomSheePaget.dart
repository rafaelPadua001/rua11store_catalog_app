import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';

class BottomSheetPage extends StatefulWidget {
  @override
  _BottomSheetState createState() => _BottomSheetState();
}

class _BottomSheetState extends State<BottomSheetPage> {
  final zipController = MaskedTextController(mask: '00000-000');
  List deliveryOptions = [];
  Map<String, dynamic>? selectedOption;

  Future<void> calculateDelivery(
    BuildContext context,
    String zipDestiny,
  ) async {
    final bool isLocal = false;
    final url = Uri.parse(
      isLocal 
      ? 'http://127.0.0.1:5000/melhorEnvio/calculate-delivery' 
      : 'https://rua11storecatalogapi-production.up.railway.app/melhorEnvio/calculate-delivery',
    ); //api local

    print(url);
    final body = jsonEncode({
      "zipcode_origin": "73080-180",
      "zipcode_destiny": zipDestiny,
      "weight": 0.5,
      "height": 10,
      "width": 15,
      "length": 20,
      "secure_value": 150,
      "quantity": 1,
    });

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        setState(() {
          deliveryOptions = result;
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Frete calculado com sucesso')));
        _buildListView(result);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro: ${response.body}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao conectar à API: $e')));
    }
  }

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
              Expanded(child: _buildListView(deliveryOptions)),
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
              final zipcode = zipController.text.trim();
              if (zipcode.isEmpty || zipcode.length < 8) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('cep inválido')));
              }
              calculateDelivery(context, zipcode);
            },
            child: Text('Buscar'),
          ),
          Divider(),
        ],
      ),
    );
  }

  Widget _buildListView(List result) {
    if (result.isEmpty) {
      return Center(child: Text("nenhum resultado"));
    }

    return ListView.builder(
      itemCount: result.length,
      itemBuilder: (context, index) {
        final Map<String, dynamic> item = result[index];

        if (item['error'] != null) {
          return ListTile(
            title: Text('${item['name']}'),
            subtitle: Text(
              "Error: ${item['error']}",
              style: TextStyle(color: Colors.red),
            ),
            leading: Container(
              width: 40,
              height: 40,
              child: Image.network(
                item["company"]["picture"],
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.local_shipping, size: 24);
                },
              ),
            ),
          );
        }
        final isSelected =
            selectedOption != null && selectedOption!['id'] == item["id"];
        return GestureDetector(
          onTap: () {
            setState(() {
              selectedOption = item;
            });
          },
          child: Card(
            color: isSelected ? Colors.blue[50] : Colors.white,
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                child: Image.network(
                  item["company"]["picture"],
                  fit: BoxFit.contain,
                  errorBuilder:
                      (context, error, stackTrace) =>
                          Icon(Icons.local_shipping),
                ),
              ),
              title: Text("${item["company"]['name']} - ${item["name"]}"),
              subtitle: Text(
                "R\$ ${item["price"]} - ${item["delivery_time"]} dias úteis",
              ),
              trailing:
                  isSelected
                      ? Icon(Icons.check_circle, color: Colors.green)
                      : Icon(Icons.radio_button_off),
            ),
          ),
        );
      },
    );
  }
}

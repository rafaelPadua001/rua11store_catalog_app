import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'zipcodeInput.dart';
import '../../services/delivery_service.dart';

class BottomSheetPage extends StatefulWidget {
  @override
  _BottomSheetState createState() => _BottomSheetState();
}

class _BottomSheetState extends State<BottomSheetPage> {
  final zipController = MaskedTextController(mask: '00000-000');
  List deliveryOptions = [];
  Map<String, dynamic>? selectedOption;

  Future<void> _handleCalculateDelivery(
    BuildContext context,
    String zipcode,
  ) async {
    final service = DeliveryService();

    try {
      final result = await service.calculateDelivery(zipDestiny: zipcode);

      setState(() {
        deliveryOptions = result;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Frete calculado com sucesso')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao calcular frete: $e')));
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
              ZipcodeInputWidget(
                zipController: zipController,
                onSearch: (zipcode) => _handleCalculateDelivery(context, zipcode),
              ),
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
              Navigator.pop(context, item);
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

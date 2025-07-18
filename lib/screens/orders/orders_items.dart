import 'package:flutter/material.dart';
import 'package:rua11store_catalog_app/controllers/ordersController.dart';
import 'package:rua11store_catalog_app/widgets/layout/trakingDetails.dart';
import '../../models/order_items.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OrderItemsWidget extends StatelessWidget {
  final List<OrderItem> items;
  final String? deliveryId;
  final apiUrl = dotenv.env['API_URL'];
  late final OrdersController controller;

  OrderItemsWidget({super.key, required this.items, this.deliveryId}) {
    controller = OrdersController(
      onTrack: (data) async {
        final url = Uri.parse('$apiUrl/melhorEnvio/shipmentTracking');
        try {
          final response = await http.post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(data),
          );
          if (response.statusCode == 200) {
            final responseData = jsonDecode(response.body);
            print('Rastreamento: $responseData');
          } else {
            print('Erro: ${response.body}');
          }
        } catch (e) {
          print('Erro de conexão $e');
        }
      },
    );
  }

  Future<Map<String, dynamic>?> handleTracking(
    Map<String, dynamic> data,
  ) async {
    final url = Uri.parse('$apiUrl/melhorEnvio/shipmentTracking');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('Rastreamento: $responseData');
        return responseData;
      } else {
        print('Erro: ${response.body}');
      }
    } catch (e) {
      print('Erro de conexão $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Itens do Pedido')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child:
                deliveryId != null
                    ? TextButton.icon(
                      icon: const Icon(Icons.local_shipping),
                      label: const Text('Rastrear pedido'),
                      onPressed: () async {
                        final data = {'order_id': deliveryId!};
                        final trackingInfo = await handleTracking(data);

                        if (trackingInfo != null) {
                          showModalBottomSheet(
                            context: context,
                            builder:
                                (context) =>
                                    TrackingDetails(item: trackingInfo),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Acompanhar pedido')),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Erro ao rastrear pedido'),
                            ),
                          );
                        }
                      },
                    )
                    : Row(
                      children: const [
                        Icon(Icons.info_outline, color: Colors.grey),
                        SizedBox(width: 8),
                        Text(
                          'Envio ainda não liberado',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    leading: Image.network(
                      '${item.productImage}',
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) =>
                              const Icon(Icons.image_not_supported),
                    ),
                    title: Text(item.name),
                    subtitle: Text('Qtd: ${item.quantity} • Preço: R\$ ${item.unitPrice.toStringAsFixed(2)}'),
                    trailing:Text('Total: R\$ ${item.totalPrice.toStringAsFixed(2)}'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

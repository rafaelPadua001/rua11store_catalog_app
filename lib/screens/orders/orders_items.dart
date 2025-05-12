import 'package:flutter/material.dart';
import '../../models/order_items.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OrderItemsWidget extends StatelessWidget {
  final List<OrderItem> items;

  const OrderItemsWidget({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final apiUrl = dotenv.env['API_URL'];
    return Scaffold(
      appBar: AppBar(title: const Text('Itens do Pedido')),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              leading: Image.network(
                '$apiUrl/${item.productImage}',
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stackTrace) =>
                        const Icon(Icons.image_not_supported),
              ),
              title: Text(item.productName),
              subtitle: Text(
                'Qtd: ${item.quantity} • Preço: R\$ ${item.productPrice}',
              ),
              trailing: Text(
                'Total: R\$ ${(item.quantity * double.parse(item.productPrice)).toStringAsFixed(2)}',
              ),
            ),
          );
        },
      ),
    );
  }
}

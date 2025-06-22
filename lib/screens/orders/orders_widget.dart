import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:rua11store_catalog_app/screens/orders/orders_items.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import '../../models/order.dart';

class OrdersWidget extends StatefulWidget {
  const OrdersWidget({super.key});

  @override
  State<OrdersWidget> createState() => _OrdersWidgetState();
}

class _OrdersWidgetState extends State<OrdersWidget> {
  final apiUrl = dotenv.env['API_URL_LOCAL'];
  //final apiUrl = dotenv.env['API_URL_LOCAL'];
  late Future<List<Order>> ordersFuture;

  @override
  void initState() {
    super.initState();
    ordersFuture = fetchOrders();
  }

  Future<List<Order>> fetchOrders() async {
    final user = await Supabase.instance.client.auth.getUser();
    final response = await http.get(
      Uri.parse('$apiUrl/order/get-order/${user.user!.id}'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Order.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load orders');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pedidos')),
      body: FutureBuilder<List<Order>>(
        future: ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final orders = snapshot.data!;
            return ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return ListTile(
                  title: Text('Pedido #${order.orderId}'),
                  subtitle: Text(
                    'Status: ${order.status} - Total: R\$${order.orderTotal.toStringAsFixed(2)}',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => OrderItemsWidget(
                              items: order.items,
                              deliveryId: order.deliveryId,
                            ),
                      ),
                    );
                  },
                );
              },
            );
          } else {
            return const Center(child: Text('No orders found'));
          }
        },
      ),
    );
  }
}

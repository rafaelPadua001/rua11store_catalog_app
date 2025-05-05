import 'package:flutter/material.dart';

class OrdersWidget extends StatelessWidget {
  const OrdersWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedidos'),
      ),
      body: const Center(
        child: Text(
          'Orders aqui',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}

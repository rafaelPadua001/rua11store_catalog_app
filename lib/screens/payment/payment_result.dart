import 'package:flutter/material.dart';

class PaymentResult extends StatefulWidget {
  PaymentResult({super.key});

  @override
  State<PaymentResult> createState() => _PaymentResultState();
}

class _PaymentResultState extends State<PaymentResult> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Payment Result')),
      body: Center(child: Text('Payment was successful!')),
    );
  }
}

import 'package:flutter/material.dart';

class PaymentResult extends StatefulWidget {
  final Map<String, dynamic> response;

  const PaymentResult({super.key, required this.response});

  @override
  State<PaymentResult> createState() => _PaymentResultState();
}

class _PaymentResultState extends State<PaymentResult> {
  @override
  Widget build(BuildContext context) {
    final status = widget.response['status'];
    final message = widget.response['message'] ?? 'Erro desconhecido';

    final isApproved = status == 'approved';

    return Scaffold(
      appBar: AppBar(title: Text('Resultado do Pagamento')),
      body: Center(
        child:
            isApproved
                ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 100),
                    SizedBox(height: 16),
                    Text(
                      'Pagamento Aprovado!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('Status: $status'),
                  ],
                )
                : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, color: Colors.red, size: 100),
                    SizedBox(height: 16),
                    Text(
                      'Pagamento Rejeitado',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('Mensagem: $message'),
                  ],
                ),
      ),
    );
  }
}

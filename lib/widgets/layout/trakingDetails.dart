import 'package:flutter/material.dart';

class TrackingDetails extends StatelessWidget {
  final Map<String, dynamic>
  item; // Pode ser substituído por um tipo específico

  const TrackingDetails({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    // Exemplo de dados (substitua conforme sua estrutura real)
    final firstEntry = item.entries.first;
    final trackingData = firstEntry.value as Map<String, dynamic>;
    final trackingCode = trackingData['tracking'] ?? 'Sem código';
    final status = trackingData['status'] ?? 'Sem código';
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Wrap(
        children: [
          Center(
            child: Container(
              width: 50,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          ListTile(
            title: const Text('Código de Rastreio'),
            subtitle: Text(trackingCode),
          ),
          ListTile(
            title: const Text('Transportadora'),
            subtitle: Text('carrier'),
          ),
          ListTile(
            title: const Text('Status do Pedido'),
            subtitle: Text(status),
          ),
          ListTile(
            title: const Text('Previsão de Entrega'),
            subtitle: Text(
              trackingData['forecast_date'] ?? 'Data não disponível',
            ),
          ),
        ],
      ),
    );
  }
}

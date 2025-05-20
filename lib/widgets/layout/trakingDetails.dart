import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class TrackingDetails extends StatelessWidget {
  final Map<String, dynamic>
  item; // Pode ser substituído por um tipo específico

  const TrackingDetails({super.key, required this.item});

  void _openTrackingUrl(trackingCode) async {
    final url = Uri.parse('https://melhorrastreio.com.br/$trackingCode');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      print('Não foi possível abrir o link');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (item.isEmpty) {
      return const Center(
        child: Text('Nenhuma informação de rastreio disponível.'),
      );
    }

    final firstEntry = item.entries.first;
    final trackingData = firstEntry.value as Map<String, dynamic>? ?? {};
    final trackingCode = trackingData['melhorenvio_tracking'] ?? 'Sem código';
    final status = trackingData['status'] ?? 'Sem status';
    final forecastDate = trackingData['forecast_date'] ?? 'Data não disponível';

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
            trailing: const Icon(Icons.open_in_new),
            onTap: () => _openTrackingUrl(trackingCode),
          ),
          ListTile(
            title: const Text('Transportadora'),
            subtitle: Text('carrier'), // Substituir pelo real se disponível
          ),
          ListTile(
            title: const Text('Status do Pedido'),
            subtitle: Text(status),
          ),
          ListTile(
            title: const Text('Previsão de Entrega'),
            subtitle: Text(forecastDate),
          ),
        ],
      ),
    );
  }
}

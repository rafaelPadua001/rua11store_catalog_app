import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class TrackingDetails extends StatelessWidget {
  final dynamic item; // Pode ser substituído por um tipo específico

  const TrackingDetails({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    // Exemplo de dados (substitua conforme sua estrutura real)
    // final trackingCode = item.trackingCode ?? 'Não informado';
    // final carrier = item.carrier ?? 'Transportadora não informada';
    // final status = item.status ?? 'Status desconhecido';
    // final estimatedDelivery = item.estimatedDelivery ?? 'Data não informada';
    // final trackingUrl = item.trackingUrl ?? '';

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
            subtitle: Text('trackingCode'),
          ),
          ListTile(
            title: const Text('Transportadora'),
            subtitle: Text('carrier'),
          ),
          ListTile(
            title: const Text('Status do Pedido'),
            subtitle: Text('status'),
          ),
          ListTile(
            title: const Text('Previsão de Entrega'),
            subtitle: Text('estimatedDelivery'),
          ),
          // if (trackingUrl.isNotEmpty)
          //   Center(
          //     child: ElevatedButton.icon(
          //       onPressed: () async {
          //         final uri = Uri.parse(trackingUrl);
          //         if (await canLaunchUrl(uri)) {
          //           await launchUrl(uri, mode: LaunchMode.externalApplication);
          //         } else {
          //           ScaffoldMessenger.of(context).showSnackBar(
          //             const SnackBar(
          //               content: Text('Não foi possível abrir o link'),
          //             ),
          //           );
          //         }
          //       },
          //       icon: const Icon(Icons.open_in_new),
          //       label: const Text('Abrir rastreamento'),
          //     ),
          //   ),
        ],
      ),
    );
  }
}

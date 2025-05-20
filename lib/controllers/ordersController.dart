import 'package:flutter_dotenv/flutter_dotenv.dart';

class OrdersController {
  final String _baseUrl;
  final Future<void> Function(Map<String, dynamic>) onTrack;

  OrdersController({required this.onTrack})
    : _baseUrl = dotenv.env['API_URL_LOCAL'] ?? '';

  Future<void> trackOrder(Map<String, dynamic> data) async {
    await onTrack(data);
  }
}

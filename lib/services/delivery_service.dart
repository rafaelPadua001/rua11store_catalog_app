import 'dart:convert';
import 'package:http/http.dart' as http;

class DeliveryService {
  final bool isLocal;

  DeliveryService({this.isLocal = false});

  Future<List> calculateDelivery({
    required String zipDestiny,
  }) async {
    final url = Uri.parse(
      isLocal
          ? 'http://127.0.0.1:5000/melhorEnvio/calculate-delivery'
          : 'https://rua11storecatalogapi-production.up.railway.app/melhorEnvio/calculate-delivery',
    );

    final body = jsonEncode({
      "zipcode_origin": "73080-180",
      "zipcode_destiny": zipDestiny,
      "weight": 0.5,
      "height": 10,
      "width": 15,
      "length": 20,
      "secure_value": 150,
      "quantity": 1,
    });

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: body,
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      return result;
    } else {
      throw Exception("Erro: ${response.body}");
    }
  }
}

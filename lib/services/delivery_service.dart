import 'dart:convert';
import 'package:http/http.dart' as http;

class DeliveryService {
  final bool isLocal;

  DeliveryService({this.isLocal = false});

  Future<List> calculateDelivery({
    required String zipDestiny,
    required List<Map<String, dynamic>> products,
    // required width,
    // required height,
    // required weight,
  }) async {
    final url = Uri.parse(
      isLocal
          ? 'http://127.0.0.1:5000/melhorEnvio/calculate-delivery'
          : 'https://rua11store-catalog-api-lbp7.onrender.com/melhorEnvio/calculate-delivery',
    );

    final body = jsonEncode({
      "zipcode_origin": "73080-180",
      "zipcode_destiny": zipDestiny,
      "products": products,
      // "weight": weight,
      // "height": height,
      // "width": width,
      // "length": 1,
      // "secure_value": 0,
      // "quantity": 1,
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

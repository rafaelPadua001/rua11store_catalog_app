import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/payment.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PaymentController {
  // final _baseUrl = dotenv.env['API_URL'] ?? '';
  final _baseUrl = dotenv.env['API_URL_LOCAL'] ?? '';
  final publicKey = dotenv.env['MP_PUBLIC_KEY'];

  Future<String?> generateCardToken({
    required String cardNumber,
    required int expirationMonth,
    required int expirationYear,
    required String securityCode,
    required String cardholderName,
    required String docType,
    required String docNumber,
  }) async {

    if(publicKey == null){
      print('chave publica (MP_PUBLIC_KEY) não configurada');
      return null;
    }


    final url = Uri.parse(
      'https://api.mercadopago.com/v1/card_tokens?public_key=${publicKey}',
    );

    final body = {
      "card_number": cardNumber,
      "expiration_month": expirationMonth,
      "expiration_year": expirationYear,
      "security_code": securityCode,
      "cardholder": {
        "name": cardholderName,
        "identification": {"type": docType, "number": docNumber},
      },
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['id']; //card_token
      } else {
        print("Erro ao gerar token: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Erro de rede $e");
      return null;
    }
  }

  Future<bool> sendPayment(Payment payment) async {
    final url = Uri.parse(_baseUrl + '/payment/payment');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": 'application/json'},
        body: json.encode(payment.toJson()),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Erro ao enviar: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Erro de rede: $e');
      return false;
    }
  }
}

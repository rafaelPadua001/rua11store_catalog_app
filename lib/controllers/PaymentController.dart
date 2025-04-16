import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/payment.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PaymentController {
   final String _baseUrl = 'http://localhost:5000/payment';
  // final _baseUrl = dotenv.env['API_URL'] ?? '';

  Future<bool> sendPayment(Payment payment) async{
    final url = Uri.parse(_baseUrl + 'payment/payment');

    try{
      final response = await http.post(
        url,
        headers: {"Content-Type": 'application/json'},
        body: json.encode(payment.toJson()),
      );

      if(response.statusCode == 200){
        return true;
      }
      else{
        print('Erro ao enviar: ${response.body}');
        return false;
      }
    }
    catch(e){
      print('Erro de rede: $e');
      return false;
    }
  }
}

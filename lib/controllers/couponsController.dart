import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/coupon.dart'; // ajuste o caminho conforme sua estrutura

class CouponsController {
  final String baseUrl = dotenv.env['API_URL'] ?? '';

  Future<Coupon?> validateCoupon({
    required String couponCode,
    required String userId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/coupon/get-coupons/$userId'),
        headers: {'Content-Type': 'application/json'},
        //   body: jsonEncode({'coupon_code': couponCode, 'user_id': userId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List && data.isNotEmpty) {
          return Coupon.fromJson(data[0]);
        } else if (data is Map<String, dynamic>) {
          return Coupon.fromJson(data);
        } else {
          return null;
        }
      } else {
        print('Erro: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Erro na requisição: $e');
      return null;
    }
  }
}

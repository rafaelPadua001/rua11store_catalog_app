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
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List && data.isNotEmpty) {
          final coupon = Coupon.fromJson(data[0]);
          await DeleteCoupon(couponId: coupon.id, userId: userId);
          return coupon;
        } else if (data is Map<String, dynamic>) {
          final coupon = Coupon.fromJson(data);
          await DeleteCoupon(couponId: coupon.id, userId: userId);
          return coupon;
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

  Future<void> DeleteCoupon({
    required int couponId,
    required String userId,
  }) async {
    print('Teste');
    final response = await http.delete(
      Uri.parse(
        '$baseUrl/coupon/delete-coupons-by-client/$couponId?userId=$userId',
      ),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      print("Cupom deletado com sucesso!");
    } else {
      print("Erro ao deletar o cupom: ${response.body}");
    }
  }
}

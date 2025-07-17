import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Commentscontroller {
  final baseUrl = dotenv.env['API_URL'];

  Future<bool> saveComment({
    required String comment,
    required String userId,
    required String userName,
    required String avatarUrl,
    required String productId,
  }) async {
    final url = Uri.parse('$baseUrl/comments/new');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'comment': comment,
          'user_id': userId,
          'user_name': userName,
          'avatar_url': avatarUrl,
          'product_id': productId,
          'status': 'ativo',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print('Erro ao salvar comentário: ${response.body}');
        return false;
      }
    } catch (error) {
      print('Exceção ao salvar comentário: $error');
      return false;
    }
  }
}

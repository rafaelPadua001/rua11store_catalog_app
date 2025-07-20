import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Commentscontroller {
  final baseUrl = dotenv.env['API_URL'];

  Future<Map<String, dynamic>?> saveComment({
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
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data;
      } else {
        print('Erro ao salvar comentário: ${response.body}');
        return null;
      }
    } catch (error) {
      print('Exceção ao salvar comentário: $error');
      return null;
    }
  }

  Future<Map<String, dynamic>?> updateComment({
    required int commentId,
    required String comment,
  }) async {
    final url = Uri.parse('$baseUrl/comments/update/${commentId}');
    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'comment': comment}),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data;
      } else {
        print('Erro ao salvar commentário: ${response.body}');
      }
    } catch (error) {
      print('Exceção ao salvar comentaro: $error');
      return null;
    }
  }

  Future<bool> deleteComment(int commentId) async {
    final url = Uri.parse('$baseUrl/comments/delete/${commentId}');
    try {
      final response = await http.delete(url);

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Falha ao deletar. Código: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Erro ao deletar comentário ${e}');
      return false;
    }
  }
}

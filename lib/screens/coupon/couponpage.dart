import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:rua11store_catalog_app/models/coupon.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../models/coupon.dart';

class CouponPage extends StatefulWidget {
  final String userId;
  const CouponPage({super.key, required this.userId});

  @override
  _StateCouponPage createState() => _StateCouponPage();
}

class _StateCouponPage extends State<CouponPage> {
  final apiUrl = dotenv.env['API_URL'];
  late Future<List<Coupon>> futureCoupons;

  @override
  void initState() {
    super.initState();
    futureCoupons = fetchCoupons();
  }

  Future<List<Coupon>> fetchCoupons() async {
    final user = await Supabase.instance.client.auth.getUser();
    final response = await http.get(
      Uri.parse('$apiUrl/coupon/get-coupons/${user.user!.id}'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Coupon.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load coupons');
    }
  }

  Future<void> deleteCoupon(String couponId, String userId) async {
    final response = await http.delete(
      Uri.parse(
        '$apiUrl/coupon/delete-coupons-by-client/$couponId?userId=$userId',
      ),
    );

    if (response.statusCode == 200) {
      setState(() {
        futureCoupons = fetchCoupons(); // Atualiza a lista após deletar
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cupom excluído com sucesso')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir cupom: ${response.body}')),
      );
    }
  }

  void confirmDelete(String couponId, String userId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmar exclusão'),
            content: const Text('Deseja realmente excluir este cupom?'),
            actions: [
              TextButton(
                child: const Text('Cancelar'),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                child: const Text(
                  'Excluir',
                  style: TextStyle(color: Colors.red),
                ),
                onPressed: () {
                  Navigator.of(context).pop(); // Fecha o diálogo
                  deleteCoupon(couponId, userId); // Chama a função de exclusão
                },
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cupons')),
      body: FutureBuilder<List<Coupon>>(
        future: futureCoupons,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhum cupom disponível.'));
          }

          final coupons = snapshot.data!;

          return ListView.builder(
            itemCount: coupons.length,
            itemBuilder: (context, index) {
              final coupon = coupons[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Parte esquerda com os dados do cupom
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              coupon.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text('Código: ${coupon.code}'),
                            Text('Desconto: ${coupon.discount}%'),
                            Text(
                              'Início: ${coupon.startDate.toLocal().toString().split(' ')[0]}',
                            ),
                            Text(
                              'Fim: ${coupon.endDate.toLocal().toString().split(' ')[0]}',
                            ),
                          ],
                        ),
                      ),

                      // Botão de deletar à direita
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed:
                            () => confirmDelete(coupon.id, widget.userId),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

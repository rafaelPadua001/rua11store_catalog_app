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
  final apiUrl = dotenv.env['API_URL_LOCAL'];
  // final List<Widget> _widgetOptions = [
  //   Card(
  //     child: Padding(
  //       padding: EdgeInsets.all(8.0),
  //       child: Column(children: [Text('Página de Cupons')]),
  //     ),
  //   ),
  //   // Center(child: Text('Página de Produtos')),
  //   // Center(child: Text('Página de Configurações')),
  // ];

  @override
  void initState() {
    super.initState();
    fetchCoupons();
  }

  Future<List<Coupon>> fetchCoupons() async {
    final user = await Supabase.instance.client.auth.getUser();
    final response = await http.get(
      Uri.parse('$apiUrl/coupon/get-coupons/${user.user!.id}'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      print(data); // 👈 Veja a estrutura real
      return data.map((json) => Coupon.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load coupons');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cupons')),
      body: FutureBuilder<List<Coupon>>(
        future: fetchCoupons(),
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
                child: ListTile(
                  title: Text(coupon.title),
                  subtitle: Text(
                    'Código: ${coupon.code}\nDesconto: ${coupon.discount.toStringAsFixed(2)}%',
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Início: ${coupon.startDate.toLocal().toString().split(' ')[0]}',
                      ),
                      Text(
                        'Fim: ${coupon.endDate.toLocal().toString().split(' ')[0]}',
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

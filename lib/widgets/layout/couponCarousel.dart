import 'package:flutter/material.dart';
import 'package:carousel_slider_x/carousel_slider_x.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:rua11store_catalog_app/screens/auth/register.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CouponCarousel extends StatefulWidget {
  const CouponCarousel({super.key});

  @override
  _CouponCarouselState createState() => _CouponCarouselState();
}

class _CouponCarouselState extends State<CouponCarousel> {
  final apiUrl = dotenv.env['API_URL'];
  List<Map<String, dynamic>> coupons = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCouponImages();
  }

  Future<void> fetchCouponImages() async {
    try {
      final endpoint = 'coupon/promotional_coupons';
      final response = await http.get(Uri.parse('$apiUrl$endpoint'));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          coupons = List<Map<String, dynamic>>.from(data);
          isLoading = false;
        });
      } else {
        throw Exception('Erro ao carregar imagens');
      }
    } catch (e) {
      print('Erro ao buscar cupons: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> applyCoupon(String couponCode, String couponTitle) async {
    final endpoint = 'coupon/get-all-client-coupons';
    final url = Uri.parse('$apiUrl$endpoint');

    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Você precisa estar logado para aplicar o cupom.'),
        ),
      );
      return;
    }
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          //'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'code': couponCode,
          'coupon_title': couponTitle,
          'client_id': user.id,
          'client_username': user.userMetadata?['display_name'],
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Coupom applied with success...')),
        );
      } else {
        print("Erro ao aplicar coupom: ${response.body}");
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Erro ao aplicar cupom')));
      }
    } catch (e) {
      print('Erro de requisição $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro de conexão com servidor')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (coupons.isEmpty) {
      return const SizedBox.shrink();
    }

    bool hasWelcomeCoupon = coupons.any(
      (coupon) => coupon['title'] == 'BEMVINDO10',
    );

    return CarouselSlider(
      options: CarouselOptions(
        //height: 350.0,
        autoPlay: true,
        enlargeCenterPage: true,
        viewportFraction: 0.9,
        aspectRatio: 4 / 3,
        autoPlayInterval: const Duration(seconds: 5),
      ),
      items:
          coupons
              .where((coupon) {
                final end_date = coupon['end_date'];
                if (end_date == null) return false;

                final endDate = DateTime.tryParse(end_date);
                if (endDate == null) return false;

                final now = DateTime.now();
                return now.isBefore(endDate); //show valid coupons
              })
              .map((coupon) {
                final imageUrl = '${coupon['image_path']}';
                final isWelcomeCoupon = coupon['title'] == 'BEMVINDO10';
                final coupon_title = coupon['title'];
                final coupon_code = coupon['code'];
                final expiry_date = coupon['end_date'];
                final discount = coupon['discount'];
                final screenHeight = MediaQuery.of(context).size.height;
                return Builder(
                  builder: (BuildContext context) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12.0),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // imagem de fundo
                          Image.network(
                            imageUrl,
                            height:
                                screenHeight * 0.25, // 25% da altura da tela
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) => const Center(
                                  child: Text('Erro ao carregar imagem'),
                                ),
                          ),

                          // gradiente sutil para melhorar contraste
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.6),
                                ],
                              ),
                            ),
                          ),

                          // conteúdo sobreposto
                          Positioned(
                            bottom: 10,
                            left: 10,
                            right: 10,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // título
                                Text(
                                  coupon_title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),

                                const SizedBox(height: 4),

                                // código + desconto
                                Text(
                                  'Código: $coupon_code • $discount% OFF',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),

                                const SizedBox(height: 2),

                                // validade
                                Text(
                                  'Válido até: $expiry_date',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white60,
                                  ),
                                ),

                                const SizedBox(height: 10),

                                // botão
                                ElevatedButton(
                                  onPressed: () {
                                    if (isWelcomeCoupon) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => Register(),
                                        ),
                                      );
                                    } else {
                                      applyCoupon(coupon_code, coupon_title);
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        isWelcomeCoupon
                                            ? Colors.black.withOpacity(0.7)
                                            : Colors.green.withOpacity(0.7),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Text(
                                    isWelcomeCoupon
                                        ? 'Cadastre-se e aproveite o cupom $coupon_code!'
                                        : 'Usar cupom',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              })
              .toList(),
    );
  }
}

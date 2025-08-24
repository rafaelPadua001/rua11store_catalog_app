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
    final endpoint = 'coupon/pick_up_coupon';
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
                            // height:
                            //    screenHeight * 0.25, // 25% da altura da tela
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

                          // código + desconto
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // conteúdo sobreposto
                                Stack(
                                  children: [
                                    // imagem de fundo
                                    AspectRatio(
                                      aspectRatio: 4 / 3,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          image: DecorationImage(
                                            image: NetworkImage(
                                              "https://via.placeholder.com/800x450",
                                            ),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    ),

                                    // bloco de conteúdo com fundo semi-transparente
                                    Positioned(
                                      bottom: 12,
                                      left: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color.fromARGB(
                                            255,
                                            14,
                                            13,
                                            13,
                                          ).withOpacity(
                                            0.5,
                                          ), // cor de fundo com opacity
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Text(
                                              coupon_title,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Color.fromARGB(
                                                  179,
                                                  253,
                                                  215,
                                                  2,
                                                ),
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Código: $coupon_code • $discount% OFF',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Color.fromARGB(
                                                  179,
                                                  253,
                                                  215,
                                                  2,
                                                ),
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Válido até: $expiry_date',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.white60,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 10),
                                            ElevatedButton(
                                              onPressed: () {
                                                if (isWelcomeCoupon) {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder:
                                                          (context) =>
                                                              Register(),
                                                    ),
                                                  );
                                                } else {
                                                  applyCoupon(
                                                    coupon_code,
                                                    coupon_title,
                                                  );
                                                }
                                              },
                                              style: TextButton.styleFrom(
                                                backgroundColor:
                                                    const Color.fromARGB(
                                                      255,
                                                      76,
                                                      0,
                                                      255,
                                                    ).withOpacity(0.7),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 10,
                                                      horizontal: 16,
                                                    ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                              child: Text(
                                                isWelcomeCoupon
                                                    ? 'Cadastre-se e aproveite o cupom $coupon_code!'
                                                    : 'Resgatar cupom',
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  color: Color.fromARGB(
                                                    255,
                                                    255,
                                                    255,
                                                    255,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
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

import 'package:flutter/material.dart';
import 'package:carousel_slider_x/carousel_slider_x.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:rua11store_catalog_app/screens/auth/register.dart';

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
      final response = await http.get(
        Uri.parse('$apiUrl/coupon/get-all-client-coupons'),
      );

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

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (coupons.isEmpty) {
      return const Center(child: Text('Nenhuma imagem disponível'));
    }

    bool hasWelcomeCoupon = coupons.any(
      (coupon) => coupon['title'] == 'BEMVINDO10',
    );

    return CarouselSlider(
      options: CarouselOptions(
        height: 350.0,
        autoPlay: true,
        enlargeCenterPage: true,
        viewportFraction: 0.9,
        aspectRatio: 16 / 9,
        autoPlayInterval: const Duration(seconds: 5),
      ),
      items:
          coupons.map((coupon) {
            final imageUrl = '$apiUrl${coupon['image_path']}';
            final isWelcomeCoupon = coupon['title'] == 'BEMVINDO10';

            return Builder(
              builder: (BuildContext context) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) => const Center(
                              child: Text('Erro ao carregar imagem'),
                            ),
                      ),
                      if (isWelcomeCoupon)
                        Positioned(
                          bottom: 10,
                          left: 10,
                          right: 10,
                          child: ElevatedButton(
                            onPressed: () {
                              // ação do botão, ex: navegar para tela de cadastro
                              print('Botão de cadastro clicado!');
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Register(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black.withOpacity(0.6),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            child: const Text(
                              'Cadastre-se e aproveite o cupom BEMVINDO10!',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          }).toList(),
    );
  }
}

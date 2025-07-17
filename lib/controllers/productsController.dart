import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/product.dart';

class ProductsController extends ChangeNotifier {
  List<Product> _products = [];
  bool _isLoading = true;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;

  Future<void> fetchProducts() async {
    _isLoading = true;
    notifyListeners();

    final url = Uri.parse(
      'https://rua11store-catalog-api-lbp7.onrender.com/products',
    );
    //final url = Uri.parse('http://localhost:5000/products');
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        _products = data.map((json) => Product.fromJson((json))).toList();
        print(_products);
      } else {
        debugPrint('Erro ao carregar produtos: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Erro na requisição: $e');
    }

    _isLoading = false;
    notifyListeners();
  }
}

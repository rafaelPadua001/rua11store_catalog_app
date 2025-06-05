import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/categories.dart';

class Categoriescontroller extends ChangeNotifier {
  List<Categories> _categories = [];
  bool _isLoading = false;

  List<Categories> get categories => _categories;
  bool get isLoading => _isLoading;

  Future<void> fetchCategories() async {
    _isLoading = true;
    notifyListeners();

    final url = Uri.parse(
      'https://rua11store-catalog-api.onrender.com//categories/',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _categories = data.map((json) => Categories.fromJson((json))).toList();
      } else {
        debugPrint('Erro ao carregar categorias: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Erro na requisição: $e');
    }

    _isLoading = false;
    notifyListeners();
  }
}

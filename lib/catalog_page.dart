import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'controllers/categoriesController.dart';
import 'controllers/productsController.dart';
import 'models/product.dart';
import 'models/categories.dart';
import 'widgets/AgeCheckDialog.dart';
import 'widgets/categories_chip.dart';
import 'widgets/layout/category_product.dart';
import 'widgets/layout/couponCarousel.dart';
import 'widgets/product_card.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});

  @override
  _CatalogPageState createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = "";
  String selectedCategoryId = "";

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showAgeDialog();
    });

    // Carrega categorias e produtos via providers
    Future.microtask(
      () =>
          Provider.of<Categoriescontroller>(
            context,
            listen: false,
          ).fetchCategories(),
    );
    Future.microtask(
      () =>
          Provider.of<ProductsController>(
            context,
            listen: false,
          ).fetchProducts(),
    );
  }

  Future<void> _showAgeDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final ageConfirmed = prefs.getBool('ageConfirmed') ?? false;

    if (!ageConfirmed) {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AgeCheckDialog(),
      );

      if (result == true) {
        await prefs.setBool('ageConfirmed', true);
      } else {
        _redirectToGoogle();
      }
    }
  }

  Future<void> _redirectToGoogle() async {
    final url = Uri.parse('https://www.google.com');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      debugPrint("Não foi possível abrir o link");
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Campo de busca
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: "Buscar produto...",
                prefixIcon: Icon(Icons.search),
                border: InputBorder.none,
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),
          const SizedBox(height: 10),

          // Lista horizontal de categorias
          SizedBox(
            height: 50,
            child: Consumer<Categoriescontroller>(
              builder: (context, controller, child) {
                if (controller.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                return ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  children:
                      controller.categories
                          .where((c) => !c.isSubcategory)
                          .map(
                            (category) => Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                              ),
                              child: CategoriesChip(
                                categories: category,
                                onTap: () {
                                  setState(() {
                                    selectedCategoryId = category.id.toString();
                                  });

                                  final productsFromProvider =
                                      Provider.of<ProductsController>(
                                        context,
                                        listen: false,
                                      ).products;

                                  final filteredProducts =
                                      productsFromProvider
                                          .where(
                                            (p) =>
                                                p.categoryId.toString() ==
                                                selectedCategoryId,
                                          )
                                          .toList();

                                  //Navigator.push(
                                  //  context,
                                  //  MaterialPageRoute(
                                  //    builder: (_) => CategoryProduct(
                                  //      category: selectedCategoryId,
                                  //      items: filteredProducts,
                                  //    ),
                                  //  ),
                                  //);
                                  Future.microtask(() {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => CategoryProduct(
                                              category: selectedCategoryId,
                                              items: filteredProducts,
                                            ),
                                      ),
                                    );
                                  });
                                },
                              ),
                            ),
                          )
                          .toList(),
                );
              },
            ),
          ),

          const SizedBox(height: 8),
          const CouponCarousel(),
          const SizedBox(height: 8),

          // Grid de produtos
          Consumer<ProductsController>(
            builder: (context, productController, child) {
              if (productController.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              final filteredProducts =
                  productController.products.where((product) {
                    return product.name.toLowerCase().contains(
                          searchQuery.toLowerCase(),
                        ) &&
                        (selectedCategoryId.isEmpty ||
                            product.categoryId.toString() ==
                                selectedCategoryId);
                  }).toList();

              if (filteredProducts.isEmpty) {
                return const Center(child: Text('Nenhum produto encontrado'));
              }

              return GridView.builder(
                padding: const EdgeInsets.all(10),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.5,
                ),
                itemCount: filteredProducts.length,
                itemBuilder: (context, index) {
                  return ProductCard(product: filteredProducts[index]);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

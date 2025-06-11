import 'package:flutter/material.dart';
import 'package:rua11store_catalog_app/models/categories.dart';
import 'package:rua11store_catalog_app/widgets/AgeCheckDialog.dart';
import 'package:rua11store_catalog_app/widgets/categories_chip.dart';
import 'package:rua11store_catalog_app/widgets/layout/category_product.dart';
import 'package:rua11store_catalog_app/widgets/layout/couponCarousel.dart';
import 'controllers/categoriesController.dart';
import 'models/product.dart';
import 'widgets/product_card.dart';
import 'controllers/productsController.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:html' as html;

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});

  @override
  _CatalogPageState createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = "";
  String selectedCategory_id = "";
  final List<Product> products = [];
  final List<Categories> categories = [];

  @override
  void initState() {
    super.initState();
    _showAgeDialog();
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

  void _showAgeDialog() async {
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
        //encerra o app
        html.window.location.href = 'https://www.google.com';
      }
    }
  }

  void _showCouponsCarrousel() async {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Buscar produto...",
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
              ),
              SizedBox(height: 10),
              SizedBox(
                height: 50,
                child: Consumer<Categoriescontroller>(
                  builder: (context, controller, child) {
                    if (controller.isLoading) {
                      return Center(child: CircularProgressIndicator());
                    }

                    return ListView(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      children:
                          controller.categories
                              .where(
                                (category) => category.isSubcategory == false,
                              )
                              .map(
                                (category) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                  ),
                                  child: CategoriesChip(
                                    categories: category,
                                    onTap: () {
                                      setState(() {
                                        selectedCategory_id =
                                            category.id.toString();
                                      });

                                      final productsFromProvider =
                                          Provider.of<ProductsController>(
                                            context,
                                            listen: false,
                                          ).products;

                                      final filteredProducts =
                                          productsFromProvider
                                              .where(
                                                (product) =>
                                                    product.categoryId
                                                        .toString() ==
                                                    selectedCategory_id,
                                              )
                                              .toList();

                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => CategoryProduct(
                                                category: selectedCategory_id,
                                                items: filteredProducts,
                                              ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              )
                              .toList(),
                    );
                  },
                ),
              ),
              SizedBox(height: 10),
              CouponCarousel(),
              SizedBox(height: 10),
              Divider(thickness: 0.1),
              Consumer<ProductsController>(
                builder: (context, productController, child) {
                  if (productController.isLoading) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final filteredProducts =
                      productController.products.where((product) {
                        return product.name.toLowerCase().contains(
                              searchQuery.toLowerCase(),
                            ) &&
                            (selectedCategory_id.isEmpty ||
                                product.categoryId == selectedCategory_id);
                      }).toList();

                  return GridView.builder(
                    shrinkWrap: true,
                    physics:
                        NeverScrollableScrollPhysics(), // Para rolagem funcionar com o pai
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 5,
                      mainAxisSpacing: 5,
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
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:rua11store_catalog_app/models/categories.dart';
import 'package:rua11store_catalog_app/widgets/categories_chip.dart';
import 'controllers/categoriesController.dart';
import 'models/product.dart';
import 'widgets/product_card.dart';
import 'controllers/productsController.dart';
import 'package:provider/provider.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});

  @override
  _CatalogPageState createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = "";
  String selectedCategory = "";
  final List<Product> products = [];
  final List<Categories> categories = [];

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    final filteredProducts =
        products.where((product) {
          return product.name.toLowerCase().contains(
                searchQuery.toLowerCase(),
              ) &&
              (selectedCategory.isEmpty ||
                  product.categoryId == selectedCategory);
        }).toList();

    return Scaffold(
      // appBar: AppBar(title: Text("Catálogo de Produtos")),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(10),
            child: TextField(
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
          ),
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
                          .where((category) => category.isSubcategory == false)
                          .map(
                            (category) => Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                              ),

                              child: CategoriesChip(
                                categories: category,
                                onTap: () {
                                  setState(() {
                                    selectedCategory = category.name;
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
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(10),
              child: Consumer<ProductsController>(
                builder: (context, productController, child) {
                  if (productController.isLoading) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final filteredProducts =
                      productController.products.where((product) {
                        return product.name.toLowerCase().contains(
                              searchQuery.toLowerCase(),
                            ) &&
                            (selectedCategory.isEmpty ||
                                product.categoryId == selectedCategory);
                      }).toList();

                  return GridView.builder(
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
            ),
          ),
        ],
      ),
    );
  }
}

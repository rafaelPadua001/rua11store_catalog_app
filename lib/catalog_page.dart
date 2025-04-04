import 'package:flutter/material.dart';
import 'package:rua11store_catalog_app/models/categories.dart';
import 'package:rua11store_catalog_app/widgets/categories_chip.dart';
import 'controllers/categoriesController.dart';
import 'models/product.dart';
import 'widgets/product_card.dart';
import 'controllers/productsController.dart';
import 'package:provider/provider.dart';

class CatalogPage extends StatefulWidget {
  @override
  _CatalogPageState createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = "";
  String selectedCategory = "";

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

  final List<Product> products = [
    // Product(
    //   name: "Produto 1",
    //   description: "Descrição do Produto 1",
    //   image: "assets/products/rollingPapers/61zuBpzampL.webp",
    //   price: "R\$ 100,00",
    //   phone: "+556195051731",
    //   category: "Sedas",
    // ),
    // Product(
    //   name: "Produto 2",
    //   description: "Descrição do Produto 2",
    //   image: "assets/products/rollingPapers/seda_zomo-miniblack-1.webp",
    //   price: "R\$ 200,00",
    //   phone: "+5561995051731",
    //   category: "Sedas",
    // ),
    // Product(
    //   name: "Produto 3",
    //   description: "Descrição do Produto 2",
    //   image: "assets/products/rollingPapers/5672.webp",
    //   price: "R\$ 200,00",
    //   phone: "+5561995051731",
    //   category: "Tabacos",
    // ),
    // Product(
    //   name: "Produto 4",
    //   description: "Descrição do Produto 2",
    //   image: "assets/products/rollingPapers/tabaco-la-revolucion-lrv-virginia-golden-30g-smoker-space-0m62hic7k3.webp",
    //   price: "R\$ 200,00",
    //   phone: "+5561995051731",
    //   category: "Tabacos",
    // ),
    // Product(
    //   name: "Produto 5",
    //   description: "Descrição do Produto 2",
    //   image: "assets/products/rollingPapers/c19178be-1ff2-47a7-927e-0cc5e005c750.webp",
    //   price: "R\$ 200,00",
    //   phone: "+5561995051731",
    //   category: "Filtros",
    // ),
    // Product(
    //   name: "Produto 6",
    //   description: "Descrição do Produto 2",
    //   image: "assets/products/rollingPapers/2_-_chillin_tips_22out1-min-1f5.webp",
    //   price: "R\$ 200,00",
    //   phone: "+5561995051731",
    //   category: "Piteiras",
    // ),
  ];

  final List<Categories> categories = [];

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

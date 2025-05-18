import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:rua11store_catalog_app/data/cart/cart_notifier.dart';
import 'package:rua11store_catalog_app/data/cart/cart_repository.dart';
import 'package:rua11store_catalog_app/main.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:rua11store_catalog_app/models/cart.dart';
import 'package:rua11store_catalog_app/screens/product/productScreen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class CategoryProduct extends StatefulWidget {
  final String category;
  final List items;
  final CartRepository cartRepository;
  CategoryProduct({
    super.key,
    required this.category,
    required this.items,
    CartRepository? cartRepository,
  }) : cartRepository = cartRepository ?? CartRepository();

  @override
  _CategoryProductState createState() => _CategoryProductState();
}

class _CategoryProductState extends State<CategoryProduct> {
  late String selectedCategory;
  late List products;
  bool _isAddingToCart = false;

  @override
  void initState() {
    super.initState();
    selectedCategory = widget.category;
    products = widget.items;
  }

  Future<dynamic> _addToCart(product) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Faça login para adicionar ao carrinho'),
          ),
        );
      }
      return;
    }

    setState(() => _isAddingToCart = true);

    try {
      final cartItem = CartItem(
        id: '',
        userId: user.id,
        productId: product.id,
        productName: product.name,
        price: product.numericPrice,
        description: product.description,
        quantity: 1,
        width: product.width,
        height: product.height,
        weight: product.weight,
        length: product.length,
        imageUrl: product.image,
        category: product.categoryId.toString(),
      );

      await widget.cartRepository.addItem(cartItem);
      // Recarrega os itens atualizados
      await widget.cartRepository.fetchCartItems(user.id);

      cartItemCount.value = widget.cartRepository.items.length;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${product.name} adicionado ao carrinho!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao adicionar: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAddingToCart = false);
      }
    }
  }

  dynamic _openWhatsApp(product) async {
    final String phone =
        dotenv.env['PHONE_NUMBER'] ??
        ''.replaceAll("+", "").replaceAll(" ", "");
    final Uri whatsappUri = Uri.parse(
      "whatsapp://send?phone=$phone&text=${Uri.encodeComponent("Olá! Tenho interesse em ${product.name}")}",
    );

    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      return;
    }

    final Uri webUri = Uri.parse(
      "https://wa.me/$phone?text=${Uri.encodeComponent("Olá! Tenho interesse em ${product.name}")}",
    );
    if (await canLaunchUrl(webUri)) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint("Não foi possível abrir o WhatsApp.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final String baseUrl = dotenv.env['API_URL'] ?? 'https://default.url/';

    return Scaffold(
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus(); // Fecha o teclado ao tocar fora
          // ou qualquer outra ação desejada
          // print('item clicado ${product}');
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text('Categories'),
            leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => MyApp()),
                );
              },
            ),
          ),
          body: GridView.builder(
            padding: EdgeInsets.all(10),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // número de colunas
              crossAxisSpacing: 10, // espaçamento horizontal
              mainAxisSpacing: 10, // espaçamento vertical
              childAspectRatio: 0.7, // proporção largura/altura do item
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              String imageUrl =
                  product.image.startsWith('http')
                      ? product.image
                      : baseUrl + product.image;

              return GestureDetector(
                onTap: () {
                  FocusScope.of(
                    context,
                  ).unfocus(); // Fecha o teclado ao tocar fora
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductScreen(product: product),
                    ),
                  );
                },
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                            child: Container(
                              constraints: const BoxConstraints(
                                maxHeight: 300,
                                maxWidth: double.infinity,
                              ),
                              child: Image.network(
                                imageUrl,
                                width: 500,
                                fit: BoxFit.contain,
                                loadingBuilder: (
                                  context,
                                  child,
                                  loadingProgress,
                                ) {
                                  if (loadingProgress == null) return child;
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Icon(
                                      Icons.image_not_supported,
                                      color: Colors.grey,
                                      size: 50,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          product.name,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'R\$ ${product.price}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: () => _openWhatsApp(product),
                              icon: const FaIcon(
                                FontAwesomeIcons.whatsapp,
                                color: Colors.white,
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed:
                                  _isAddingToCart
                                      ? null
                                      : () => _addToCart(product),
                              icon:
                                  _isAddingToCart
                                      ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : const Icon(
                                        Icons.add_shopping_cart,
                                        color: Colors.white,
                                      ),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.deepPurpleAccent,
                                disabledBackgroundColor: Colors.deepPurpleAccent
                                    .withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

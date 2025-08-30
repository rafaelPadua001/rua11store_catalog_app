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
        imageUrl: product.thumbnail_path,
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
            padding: const EdgeInsets.all(10),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // número de colunas
              childAspectRatio:
                  0.6, // largura/altura do card, ajuste se quiser mais ou menos alto
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              String imageUrl =
                  product.thumbnailPath.startsWith('http')
                      ? product.thumbnailPath
                      : baseUrl + product.thumbnailPath;

              return GestureDetector(
                onTap: () {
                  FocusScope.of(context).unfocus();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductScreen(product: product),
                    ),
                  );
                },
                child: Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Imagem do produto
                      AspectRatio(
                        aspectRatio: 1, // quadrado
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              if (product.stockQuantity == 0)
                                Positioned(
                                  bottom: 8,
                                  left: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(
                                        255,
                                        98,
                                        0,
                                        255,
                                      ).withOpacity(0.8),
                                      borderRadius: BorderRadius.circular(
                                        4,
                                      ), // cantos arredondados
                                      border:
                                          null, // garante que não tenha borda
                                    ),
                                    child: const Text(
                                      'Esgotado',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      // Conteúdo textual + botões
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'R\$ ${product.price}',
                                maxLines: 1,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurpleAccent,
                                ),
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
                                  const SizedBox(width: 4),
                                  IconButton(
                                    onPressed:
                                        _isAddingToCart
                                            ? null
                                            : () => _addToCart(product),
                                    icon:
                                        _isAddingToCart
                                            ? const SizedBox(
                                              width: 10,
                                              height: 10,
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
                                      backgroundColor: Colors.black,
                                      disabledBackgroundColor: Colors.grey
                                          .withOpacity(0.5),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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

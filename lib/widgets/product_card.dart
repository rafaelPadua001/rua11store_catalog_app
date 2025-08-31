import 'package:flutter/material.dart';
import 'package:rua11store_catalog_app/data/cart/cart_notifier.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';
import '../../data/cart/cart_repository.dart';
import '../models/cart.dart';
import '../screens/product/productScreen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final String? zipCode;
  final Map<String, dynamic>? company;
  final CartRepository cartRepository;

  ProductCard({
    super.key,
    required this.product,
    this.zipCode,
    this.company,
    CartRepository? cartRepository,
  }) : cartRepository = cartRepository ?? CartRepository();

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _isAddingToCart = false;

  @override
  void initState() {
    super.initState();
  }

  void _openWhatsApp() async {
    final String phone =
        dotenv.env['PHONE_NUMBER'] ??
        ''.replaceAll("+", "").replaceAll(" ", "");
    final Uri whatsappUri = Uri.parse(
      "whatsapp://send?phone=$phone&text=${Uri.encodeComponent("Olá! Tenho interesse em ${widget.product.name}")}",
    );

    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      return;
    }

    final Uri webUri = Uri.parse(
      "https://wa.me/$phone?text=${Uri.encodeComponent("Olá! Tenho interesse em ${widget.product.name}")}",
    );
    if (await canLaunchUrl(webUri)) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint("Não foi possível abrir o WhatsApp.");
    }
  }

  Future<void> _addToCart() async {
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
        productId: widget.product.id,
        productName: widget.product.name,
        price: widget.product.numericPrice,
        description: widget.product.description,
        quantity: 1,
        width: widget.product.width,
        height: widget.product.height,
        weight: widget.product.weight,
        length: widget.product.length,
        imageUrl: widget.product.thumbnailPath,
        category: widget.product.categoryId.toString(),
      );

      await widget.cartRepository.addItem(cartItem);
      // Recarrega os itens atualizados
      await widget.cartRepository.fetchCartItems(user.id);

      cartItemCount.value = widget.cartRepository.items.length;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.product.name} adicionado ao carrinho!'),
          ),
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

  @override
  Widget build(BuildContext context) {
    final String baseUrl =
        dotenv.env['API_URL_LOCAL'] ?? 'https://default.url/';

    String imageUrl =
        widget.product.thumbnailPath.startsWith('http')
            ? widget.product.thumbnailPath
            : baseUrl + widget.product.thumbnailPath;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductScreen(product: widget.product),
          ),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 1,
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: 40,
                    maxWidth: 40, // Ajuste esse valor conforme necessário
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.network(
                          imageUrl,
                          width: 40,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
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
                      if (widget.product.stockQuantity == 0)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(
                                255,
                                255,
                                0,
                                0,
                              ).withOpacity(0.8),
                              borderRadius: BorderRadius.circular(
                                4,
                              ), // cantos arredondados
                              border: null, // garante que não tenha borda
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
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      widget.product.name,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'R\$ ${widget.product.price}',
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                        fontSize: 16,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: _openWhatsApp,
                          icon: const FaIcon(
                            FontAwesomeIcons.whatsapp,
                            color: Colors.white,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 4), // espaçamento entre os botões
                        IconButton(
                          onPressed: _isAddingToCart ? null : _addToCart,
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
                            backgroundColor: Colors.black,
                            disabledBackgroundColor: Colors.grey.withOpacity(
                              0.5,
                            ),
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
  }
}

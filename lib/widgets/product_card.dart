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
        productName: widget.product.name,
        price: widget.product.numericPrice,
        description: widget.product.description,
        quantity: 1,
        width: widget.product.width,
        height: widget.product.height,
        weight: widget.product.weight,
        length: widget.product.length,
        imageUrl: widget.product.image,
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
    String baseUrl = "https://rua11storecatalogapi-production.up.railway.app/";

    String imageUrl =
        widget.product.image.startsWith('http')
            ? widget.product.image
            : baseUrl + widget.product.image;
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        elevation: 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.image_not_supported,
                      size: 50,
                      color: Colors.grey,
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                widget.product.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: Text(
                'R\$ ${widget.product.price}',
                style: const TextStyle(color: Colors.black),
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
                  style: IconButton.styleFrom(backgroundColor: Colors.green),
                ),
                const SizedBox(width: 8), // espaçamento entre os botões
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
    );
  }
}

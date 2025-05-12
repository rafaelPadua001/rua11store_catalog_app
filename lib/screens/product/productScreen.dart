import 'package:flutter/material.dart';
import 'package:flutter_spinbox/flutter_spinbox.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:rua11store_catalog_app/screens/payment/checkoutPage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/product.dart';
import '../../widgets/layout/bottomSheePaget.dart';
import '../../data/cart/cart_repository.dart';
import '../../models/cart.dart';
import '../../data/cart/cart_notifier.dart';

class ProductScreen extends StatefulWidget {
  final Product product;
  final CartRepository cartRepository;

  ProductScreen({
    super.key,
    required this.product,
    CartRepository? cartRepository,
  }) : cartRepository = cartRepository ?? CartRepository();

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final apiUrl = dotenv.env['API_URL'];
  //final apiUrl = dotenv.env['API_URL_LOCAL'];
  double quantity = 1;
  Map<String, dynamic>? selectedDelivery;
  String? selectedZipCode;
  bool _isAddingToCart = false;
  final bool _isBuying = false;

  Future<User?> verifyLogged() async {
    final session = Supabase.instance.client.auth.currentSession;
    final user = session?.user;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Faça login para adicionar ao carrinho')),
      );
    }

    return user;
  }

  Future<void> _addToCart() async {
    final user = await verifyLogged();

    if (user == null) return;

    setState(() => _isAddingToCart = true);

    try {
      final cartItem = CartItem(
        id: '',
        userId: user.id,
        productId: widget.product.id,
        productName: widget.product.name,
        price: widget.product.numericPrice,
        description: widget.product.description,
        quantity: quantity.toInt(),
        width: widget.product.weight,
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

        // Reabre o menu (caso exista uma função _showCartMenu)
        Navigator.of(context).pop(); // fecha se estiver aberto
        await Future.delayed(const Duration(milliseconds: 50));
        //_showCartMenu(context);
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

  Future<void> _buyNow() async {
    final user = await verifyLogged();

    if (user == null) {
      print('Usuário é nulo, encerrando _buyNow');
      return;
    }

    if (selectedDelivery == null || selectedZipCode == null) {
      print('Delivery ou CEP não selecionado');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione uma opção de entrega e insira o CEP'),
        ),
      );
      return;
    }

    final productData = {
      'id': widget.product.id,
      'name': widget.product.name,
      'image': widget.product.image,
      'price': widget.product.price,
      'width': widget.product.width,
      'height': widget.product.height,
      'length': widget.product.length,
      'weight': widget.product.weight,
      'stock_quantity': widget.product.quantity,
      'quantity': quantity,
    };

    final deliveryData = {
      'id': selectedDelivery?['id'],
      'name': selectedDelivery?['name'],
      'price': selectedDelivery?['price'],
      'type': selectedDelivery?['type'],
    };

    final payload = {
      'user': user.id,
      'product': productData,
      'delivery': deliveryData,
      'zipcode': selectedZipCode,
    };

    debugPrint('Enviando para API: $payload');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Compra iniciada com sucesso!')),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => CheckoutPage(
              userId: user.id,
              userEmail: user.email.toString(),
              products: [productData],
              delivery: deliveryData,
              zipCode: selectedZipCode.toString(),
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // final cartProvider = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(widget.product.name)),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            _buildProductImage(apiUrl),
            SizedBox(height: 10),
            _buildPriceCard(),
            _buildDeliveryCard(),
            _buildDescription(),
          ],
        ),
      ),
      bottomNavigationBar: _buildCardActions(),
    );
  }

  Widget _buildProductImage(apiUrl) {
    return Image.network(
      apiUrl + widget.product.image,
      width: 340,
      fit: BoxFit.cover,
    );
  }

  Widget _buildPriceCard() {
    final unitPrice = double.tryParse(widget.product.price) ?? 0.0;
    final totalPrice = unitPrice * quantity;
    return Card(
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Total: R\$ ${totalPrice.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildDeliveryCard() {
    return Card(
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                selectedDelivery != null
                    ? 'Delivery price: R\$ ${double.parse(selectedDelivery!['price'].toString())}'
                    : 'Delivery Price: R\$ - ',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: Icon(Icons.arrow_forward_ios, size: 15),
              tooltip: 'Mais detalhes',
              onPressed: () async {
                final result = await showModalBottomSheet(
                  context: context,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  builder:
                      (context) => BottomSheetPage(
                        products: [
                          {
                            "width": widget.product.width,
                            "height": widget.product.height,
                            "weight": widget.product.weight,
                            "length": widget.product.length,
                            "secure_value": 0,
                            "quantity": quantity,
                          },
                        ],
                      ),
                );

                if (result != null && result is Map) {
                  final zip = result['zipCode'] ?? result['zipcode'];
                  if (zip is String) {
                    setState(() {
                      selectedDelivery = result['delivery'];
                      selectedZipCode = zip;
                    });
                  } else {
                    debugPrint(
                      'Erro: zipCode está nulo ou em formato inválido',
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescription() {
    return Card(
      elevation: 5,
      child: ExpansionTile(
        title: const Text(
          'Description',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              'Description: ${widget.product.description}',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardActions() {
    return Container(
      color: Colors.deepPurple,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              IconButton(
                color: Colors.white,
                icon: Icon(Icons.comment),
                tooltip: 'message',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Botão comentar ainda não está pronto'),
                    ),
                  );
                },
              ),
              SizedBox(width: 8),
              IconButton(
                color: Colors.white,
                icon: Icon(Icons.add_shopping_cart_sharp),
                tooltip: 'cart',
                onPressed: _isAddingToCart ? null : _addToCart,
              ),
              SizedBox(width: 8),
              SizedBox(
                width: 135,
                child: SpinBox(
                  min: 1,
                  max:
                      (widget.product.stockQuantity >= 1)
                          ? widget.product.stockQuantity.toDouble()
                          : 1.0,
                  value: 1,
                  onChanged: (value) {
                    setState(() {
                      if (value >= widget.product.stockQuantity) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Você atingiu o estoque máximo disponível.',
                            ),
                          ),
                        );
                      }
                      quantity = value;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Quantidade:',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              SizedBox(width: 6),
              Expanded(
                child: TextButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                    backgroundColor: Colors.deepPurple,
                    minimumSize: Size(double.infinity, 50),
                  ),
                  onPressed: () async {
                    await _buyNow();
                  },

                  child: Text('Buy Now', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

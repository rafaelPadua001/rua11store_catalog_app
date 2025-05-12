import 'package:flutter/material.dart';
import 'package:flutter_spinbox/flutter_spinbox.dart';
import 'package:rua11store_catalog_app/models/cart.dart';
import 'package:rua11store_catalog_app/screens/payment/checkoutPage.dart';
import '../../data/cart/cart_repository.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CartWidget extends StatefulWidget {
  final String userId;

  const CartWidget({super.key, required this.userId});

  @override
  State<CartWidget> createState() => _CartWidgetState();
}

class _CartWidgetState extends State<CartWidget> {
  final CartRepository cartRepository = CartRepository();
  final apiUrl = dotenv.env['API_URL'];
  List<CartItem> cartItems = [];
  bool isLoading = true;
  int quantity = 1;

  @override
  void initState() {
    super.initState();
    _loadCartItems();
  }

  Future<void> _loadCartItems() async {
    final items = await cartRepository.fetchCartItems(widget.userId);
    setState(() {
      cartItems = items;
      isLoading = false;
    });
  }

  double get totalCartValue {
    return cartItems.fold(
      0.0,
      (sum, item) => sum + (item.price * item.quantity),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : cartItems.isEmpty
              ? const Center(child: Text('Carrinho vazio'))
              : ListView.builder(
                itemCount: cartItems.length + 1, // Adiciona +1 para o total
                itemBuilder: (context, index) {
                  if (index < cartItems.length) {
                    final item = cartItems[index];
                    return ListTile(
                      leading: Image.network(
                        '$apiUrl${item.imageUrl}',
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) =>
                                const Icon(Icons.image_not_supported),
                      ),
                      title: Text(item.productName),
                      subtitle: SizedBox(
                        width: 100,
                        child: SpinBox(
                          min: 1,
                          max: 100,
                          value: item.quantity.toDouble(),
                          onChanged: (value) {
                            setState(() {
                              item.quantity = value.toInt();
                            });
                          },
                          decoration: const InputDecoration(
                            labelText: 'Qtd',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('R\$ ${item.price.toStringAsFixed(2)}'),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                cartItems.removeAt(index);
                                cartRepository.removeItem(item.id);
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${item.productName} removido'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  } else {
                    // Última linha: total
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // _buildCardAddress(context),
                          // Text(
                          //   'shipping price R\$ 0.00',
                          //   style: TextStyle(fontWeight: FontWeight.bold),
                          // ),
                          Text(
                            'Total do Carrinho: R\$ ${totalCartValue.toStringAsFixed(2)} + frete',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Center(child: _buildCardAddress(context)),
                        ],
                      ),
                    );
                  }
                },
              ),
    );
  }
}

Widget _buildCardAddress(BuildContext context) {
  return ElevatedButton(
    onPressed: () {
      print('caculate shipping + payment');
      // Navigator.push(
      //   context,
      //   Material(
      //     PageRoute(
      //       builder:
      //           (context) => CheckoutPage(
      //             userId: userId,
      //             userEmail: userEmail,
      //             products: products,
      //             delivery: delivery,
      //             zipCode: zipCode,
      //           ),
      //     ),
      //   ),
      // );
    },
    child: Text('caculate shiping + payment'),
  );
}

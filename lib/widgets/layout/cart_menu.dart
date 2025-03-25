import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/cart/cart_repository.dart';
import '../../models/cart.dart';

class CartMenu extends StatefulWidget {
  const CartMenu({Key? key}) : super(key: key);

  @override
  _CartMenuState createState() => _CartMenuState();
}

class _CartMenuState extends State<CartMenu> {
  final CartRepository _cartRepository = CartRepository();
  List<CartItem> cartItems = []; // Usando o modelo diretamente
  bool isLoading = true;
  bool isMenuOpen = false;

  Future<void> _loadCartItems() async {
    if (!mounted) return;
    
    setState(() => isLoading = true);
    
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (!mounted) return;
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Faça login para ver seu carrinho')),
        );
        return;
      }

      final items = await _cartRepository.getCartItems(user.id);
      if (!mounted) return;
      setState(() {
        cartItems = items;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar carrinho: ${e.toString()}')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadCartItems();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Stack(
        children: [
          const Icon(Icons.shopping_cart, color: Colors.white),
          if (cartItems.isNotEmpty)
            Positioned(
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  cartItems.length.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      onPressed: () async {
        if (isMenuOpen) return;
        
        await _loadCartItems();
        
        setState(() => isMenuOpen = true);
        
        await showMenu(
          context: context,
          position: RelativeRect.fromLTRB(
            MediaQuery.of(context).size.width - 300, // Largura maior
            80, // Posição mais alta
            0,
            0,
          ),
          items: [
            PopupMenuItem(
              height: 400, // Altura fixa
              child: SizedBox(
                width: 300,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Seu Carrinho',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const Divider(),
                    if (isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (cartItems.isEmpty)
                      const Center(
                        child: Text('Seu carrinho está vazio'),
                      )
                    else
                      Column(
                        children: [
                          SizedBox(
                            height: 250, // Altura fixa para a lista
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: cartItems.length,
                              itemBuilder: (context, index) {
                                final item = cartItems[index];
                                return ListTile(
                                  title: Text(item.productName),
                                  subtitle: Text('Qtd: ${item.quantity}'),
                                  trailing: Text(
                                    'R\$ ${item.price.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              onPressed: () {
                                Navigator.pop(context); // Fecha o menu
                                // Adicione sua lógica de checkout aqui
                              },
                              child: const Text('Finalizar Compra'),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ).then((_) => setState(() => isMenuOpen = false));
      },
    );
  }
}
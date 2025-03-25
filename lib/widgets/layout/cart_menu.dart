import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/cart/cart_repository.dart';
import '../../models/cart.dart';

class CartMenu extends StatefulWidget {
  @override
  _CartMenuState createState() => _CartMenuState();
}

class _CartMenuState extends State<CartMenu> {
  final CartRepository _cartRepository = CartRepository();
  List<Map<String, dynamic>> cartItems = [];
  bool isLoading = true;

  Future<void> _loadCartItems() async {
    setState(() => isLoading = true);
    
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Faça login para ver seu carrinho')),
        );
        return;
      }

      final List<CartItem> items = await _cartRepository.getCartItems(user.id);
      setState(() {
        cartItems = items.map((item) => item.toJson()).toList();
        isLoading = false;
      });
    } catch (e) {
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
      icon: Icon(
        Icons.shopping_cart,
        color: Colors.white,
      ),
      onPressed: () async {
        await _loadCartItems();
        
        showMenu(
          context: context,
          position: RelativeRect.fromLTRB(
            MediaQuery.of(context).size.width - 200,
            100,
            0,
            0,
          ),
          items: [
            PopupMenuItem(
              child: Container(
                width: 300,
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Seu Carrinho', style: TextStyle(fontWeight: FontWeight.bold)),
                    Divider(),
                    if (isLoading)
                      Center(child: CircularProgressIndicator())
                    else if (cartItems.isEmpty)
                      Text('Seu carrinho está vazio')
                    else
                      Column(
                        children: [
                          ...cartItems.map((item) => ListTile(
                            title: Text(item['product_name']),
                            subtitle: Text('Qtd: ${item['quantity']}'),
                            trailing: Text('R\$ ${item['price'].toStringAsFixed(2)}'),
                          )),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              print('Checkout clicked');
                            },
                            child: Text('Finalizar Compra'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
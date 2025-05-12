import 'package:flutter/material.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:flutter_spinbox/flutter_spinbox.dart';
import 'package:rua11store_catalog_app/models/cart.dart';
import 'package:rua11store_catalog_app/screens/payment/checkoutPage.dart';
import '../../data/cart/cart_repository.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../widgets/layout/zipcodeInput.dart';
import '../../services/delivery_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CartWidget extends StatefulWidget {
  final String userId;

  const CartWidget({super.key, required this.userId});

  @override
  State<CartWidget> createState() => _CartWidgetState();
}

class _CartWidgetState extends State<CartWidget> {
  final CartRepository cartRepository = CartRepository();
  final TextEditingController _zipController = MaskedTextController(
    mask: '00000-000',
  );
  final apiUrl = dotenv.env['API_URL'];
  List<CartItem> cartItems = [];
  List deliveryOptions = [];
  Map<String, dynamic>? selectedOption;
  bool isMenuOpen = false;
  bool isLoading = true;
  int quantity = 1;
  OverlayEntry? _menuOverlayEntry;
  double deliveryFee = 0.0;

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

  double _calculateSubtotal() {
    try {
      if (cartItems.isEmpty) return 0.0;

      double subtotal = 0.0;

      for (var item in cartItems) {
        final price = item.price;
        final quantity = item.quantity;

        if (quantity == null) continue;

        subtotal += price * quantity;
      }

      return subtotal;
    } catch (e) {
      debugPrint('Erro ao calcular subtotal: $e');
      return 0.0;
    }
  }

  double _calculateTotal() {
    return _calculateSubtotal() + deliveryFee;
  }

  Future<void> _handleCalculateDelivery(String zipcode) async {
    final service = DeliveryService();

    final List<Map<String, dynamic>> products =
        cartItems.map((item) {
          return {
            "width": item.width,
            "height": item.height,
            "weight": item.weight,
            "length": item.length ?? 1,
            "quantity": int.tryParse(item.quantity.toString() ?? '1') ?? 1,
            "secure_value": item.price, // valor para seguro, opcional
          };
        }).toList();

    try {
      final result = await service.calculateDelivery(
        zipDestiny: zipcode,
        products: products,
      );

      setState(() {
        deliveryOptions = result;
        selectedOption = null; // Reseta a seleção ao calcular novo frete
      });
      _updateMenuContent();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Frete calculado com sucesso')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao calcular frete: $e')));
    }
  }

  void _updateMenuContent() {
    if (_menuOverlayEntry != null) {
      _menuOverlayEntry!.markNeedsBuild();
    }
  }

  void _closeMenu() {
    if (_menuOverlayEntry != null) {
      _menuOverlayEntry!.remove();
      _menuOverlayEntry = null;
    }
    isMenuOpen = false;
  }

  String _formatCurrency(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
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
                          ExpansionTile(
                            title: Text('Endereço de Entrega'),
                            leading: Icon(Icons.location_on),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: ZipcodeInputWidget(
                                  zipController: _zipController,
                                  onSearch:
                                      (zipcode) =>
                                          _handleCalculateDelivery(zipcode),
                                ),
                              ),

                              // Wrap com Container para simular o Expanded
                              SizedBox(
                                height:
                                    175, // ou qualquer altura apropriada que você deseja
                                child: _buildListView(deliveryOptions),
                              ),
                            ],
                          ),
                          Text(
                            'Taxa de entrega: ${_formatCurrency(deliveryFee)}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          Text(
                            'Total: ${_formatCurrency(_calculateTotal())}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 24),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              onPressed:
                                  selectedOption == null
                                      ? null
                                      : () {
                                        _closeMenu();
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Compra finalizada com ${selectedOption!["company"]["name"]} - ${selectedOption!["name"]}, valor R\$ ${selectedOption!["price"]}',
                                            ),
                                          ),
                                        );
                                        final user =
                                            Supabase
                                                .instance
                                                .client
                                                .auth
                                                .currentUser;
                                        if (user == null) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Usuário não autenticado',
                                              ),
                                            ),
                                          );

                                          return;
                                        }
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) => CheckoutPage(
                                                  userId: user.id,
                                                  userEmail: user.email ?? '',
                                                  products:
                                                      cartItems
                                                          .map(
                                                            (item) =>
                                                                item.toMap(),
                                                          )
                                                          .toList(), // Converte CartItem para Map
                                                  delivery: selectedOption!,
                                                  zipCode: _zipController.text,
                                                ),
                                          ),
                                        );
                                      },
                              child: Text(
                                selectedOption == null
                                    ? 'Escolha uma opção de frete'
                                    : 'Finalizar Compra',
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
    );
  }

  Widget _buildListView(List result) {
    if (result.isEmpty) {
      return const Center(child: Text("Digite um CEP para calcular o frete"));
    }

    return ListView.builder(
      itemCount: result.length,
      itemBuilder: (context, index) {
        final Map<String, dynamic> item = result[index];

        if (item['error'] != null) {
          return ListTile(
            title: Text('${item['name']}'),
            subtitle: Text(
              "Error: ${item['error']}",
              style: TextStyle(color: Colors.red),
            ),
            leading: SizedBox(
              width: 40,
              height: 35,
              child: Image.network(
                item["company"]["picture"],
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.local_shipping, size: 24);
                },
              ),
            ),
          );
        }

        final isSelected =
            selectedOption != null && selectedOption!['id'] == item["id"];
        return GestureDetector(
          onTap: () {
            setState(() {
              selectedOption = item;
              deliveryFee = double.tryParse(item['price'].toString()) ?? 0.0;
              _updateMenuContent(); // Atualiza o menu para mostrar a seleção
            });
          },
          child: Card(
            color: isSelected ? Colors.blue[50] : Colors.white,
            child: ListTile(
              leading: SizedBox(
                width: 40,
                height: 40,
                child: Image.network(
                  item["company"]["picture"],
                  fit: BoxFit.contain,
                  errorBuilder:
                      (context, error, stackTrace) =>
                          Icon(Icons.local_shipping),
                ),
              ),
              title: Text("${item["company"]['name']} - ${item["name"]}"),
              subtitle: Text(
                "R\$ ${item["price"]} - ${item["delivery_time"]} dias úteis",
              ),
              trailing:
                  isSelected
                      ? Icon(Icons.check_circle, color: Colors.green)
                      : Icon(Icons.radio_button_off),
            ),
          ),
        );
      },
    );
  }
}

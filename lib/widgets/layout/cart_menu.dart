import 'package:flutter/material.dart';
import 'package:flutter_spinbox/flutter_spinbox.dart';
import 'package:rua11store_catalog_app/screens/payment/checkoutPage.dart';
import 'package:rua11store_catalog_app/services/delivery_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/cart/cart_repository.dart';
// import '../../models/cart.dart';
import '../../data/cart/cart_notifier.dart';
import 'zipcodeInput.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';

class CartMenu extends StatefulWidget {
  const CartMenu({super.key});

  @override
  _CartMenuState createState() => _CartMenuState();
}

class _CartMenuState extends State<CartMenu> {
  final CartRepository _cartRepository = CartRepository();
  final TextEditingController _zipController = MaskedTextController(
    mask: '00000-000',
  );
  List deliveryOptions = [];
  Map<String, dynamic>? selectedOption;
  List<Map<String, dynamic>> cartItems = [];
  bool isLoading = true;
  bool isMenuOpen = false;
  bool _isDisposed = false;
  OverlayEntry? _menuOverlayEntry;
  double deliveryFee = 0.0;

  @override
  void initState() {
    super.initState();
    _loadCartItems();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _menuOverlayEntry?.remove();
    super.dispose();
  }

  Future<void> _loadCartItems() async {
    if (_isDisposed) return;

    setState(() => isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (_isDisposed) return;
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Faça login para ver seu carrinho')),
        );
        return;
      }

      await _cartRepository.fetchCartItems(user.id);

      if (_isDisposed) return;
      setState(() {
        cartItems = _cartRepository.items.map((item) => item.toJson()).toList();
        cartItemCount.value = cartItems.length;
        isLoading = false;
      });
    } catch (e) {
      if (_isDisposed) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar carrinho: ${e.toString()}')),
      );
    }
  }

  Future<void> _removeItem(int index) async {
    if (_isDisposed || index < 0 || index >= cartItems.length) return;

    final BuildContext currentContext = context;

    final item = cartItems[index];
    final itemId = item['id']?.toString();

    if (itemId == null) {
      ScaffoldMessenger.of(
        currentContext,
      ).showSnackBar(const SnackBar(content: Text('ID do item inválido')));
      return;
    }

    final previousItems = List<Map<String, dynamic>>.from(cartItems);

    if (!_isDisposed) {
      setState(() => cartItems.removeAt(index));
      cartItemCount.value = cartItems.length;
    }

    try {
      await _cartRepository.removeItem(itemId);
    } catch (e) {
      if (!_isDisposed) {
        setState(() {
          cartItems = previousItems;
          cartItemCount.value = cartItems.length;
        });
      }
      ScaffoldMessenger.of(currentContext).showSnackBar(
        SnackBar(content: Text('Erro ao remover item: ${e.toString()}')),
      );
    }

    if (!_isDisposed && cartItems.isNotEmpty) {
      _updateMenuContent(); // Atualiza o conteúdo sem fechar o menu
    }
  }

  Future<void> _handleCalculateDelivery(String zipcode) async {
    final service = DeliveryService();

    final List<Map<String, dynamic>> products =
        cartItems.map((item) {
          return {
            "width": item['width'],
            "height": item['height'],
            "weight": item['weight'],
            "length": item['length'] ?? 1,
            "quantity": int.tryParse(item['quantity']?.toString() ?? '1') ?? 1,
            "secure_value": item['price'], // valor para seguro, opcional
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

  void _showCartMenu(BuildContext context) {
    if (isMenuOpen) return;

    isMenuOpen = true;

    final overlayState = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);

    _menuOverlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            left: position.dx - 205,
            top: position.dy + 50,
            child: Material(
              elevation: 8,
              child: Container(
                width: 300,
                height: 800,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: _buildMenuContent(),
              ),
            ),
          ),
    );

    overlayState.insert(_menuOverlayEntry!);
  }

  void _closeMenu() {
    if (_menuOverlayEntry != null) {
      _menuOverlayEntry!.remove();
      _menuOverlayEntry = null;
    }
    isMenuOpen = false;
  }

  void _updateMenuContent() {
    if (_menuOverlayEntry != null) {
      _menuOverlayEntry!.markNeedsBuild();
    }
  }

  String _formatPrice(dynamic price) {
    try {
      if (price == null) return 'R\$ 0,00';

      // Se for string
      if (price is String) {
        String cleaned = price.replaceAll(RegExp(r'[^0-9.,]'), '');

        // Se tiver vírgula, trata como formato brasileiro
        if (cleaned.contains(',')) {
          cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');
        }

        double value = double.tryParse(cleaned) ?? 0.0;
        return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
      }

      // Se for num (int ou double), apenas formata com 2 casas decimais
      if (price is num) {
        double value = price.toDouble();
        return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
      }

      return 'R\$ 0,00';
    } catch (e) {
      debugPrint('Erro ao formatar preço: $e');
      return 'R\$ 0,00';
    }
  }

  String _formatCurrency(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  double _calculateSubtotal() {
    try {
      if (cartItems.isEmpty) return 0.0;

      double subtotal = 0.0;

      for (var item in cartItems) {
        if (item.containsKey('price')) {
          final price = item['price'] * item['quantity'];

          if (price == null) continue;

          if (price is num) {
            subtotal += price.toDouble();
          } else if (price is String) {
            // caso por algum motivo venha string, ainda trata
            String cleaned = price.replaceAll(RegExp(r'[^0-9,\.]'), '');
            cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');
            subtotal += double.tryParse(cleaned) ?? 0.0;
          }
        }
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

  Widget _buildMenuContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Seu Carrinho',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            IconButton(icon: const Icon(Icons.close), onPressed: _closeMenu),
          ],
        ),
        const Divider(),
        if (isLoading)
          const Center(child: CircularProgressIndicator())
        else if (cartItems.isEmpty)
          const Center(child: Text('Seu carrinho está vazio'))
        else
          Expanded(
            child: Column(
              children: [
                SizedBox(
                  height: 145,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      final itemId = item['id']?.toString() ?? index.toString();
                      String baseUrl =
                          "https://rua11storecatalogapi-production.up.railway.app/";

                      String imageUrl =
                          item['image_url'].startsWith('http')
                              ? item['image_url']
                              : baseUrl + item['image_url'];

                      return Card(
                        child: Dismissible(
                          key: Key(itemId),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 50),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          onDismissed: (direction) => _removeItem(index),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                // Imagem
                                item['image_url'] != null
                                    ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        imageUrl,
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(Icons.broken_image),
                                      ),
                                    )
                                    : const Icon(Icons.image_not_supported),
                                const SizedBox(width: 6),

                                // Informações do produto
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['product_name'] ??
                                            'Produto sem nome',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      SizedBox(
                                        width: 120,
                                        child: SpinBox(
                                          min: 1,
                                          max: 100,
                                          value:
                                              item['quantity']?.toDouble() ??
                                              1.0,
                                          onChanged: (value) {
                                            setState(() {
                                              item['quantity'] = value.toInt();
                                            });

                                            _updateMenuContent();
                                          },
                                          decoration: const InputDecoration(
                                            labelText: 'Quantidade:',
                                            border: OutlineInputBorder(),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Preço e botão excluir
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      _formatPrice(
                                        (item['price'] is String
                                                ? double.tryParse(
                                                      item['price'],
                                                    ) ??
                                                    0.0
                                                : item['price'] * 1.0) *
                                            (item['quantity'] ?? 1),
                                      ),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => _removeItem(index),
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
                ExpansionTile(
                  title: Text('Endereço de Entrega'),
                  leading: Icon(Icons.location_on),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ZipcodeInputWidget(
                        zipController: _zipController,
                        onSearch:
                            (zipcode) => _handleCalculateDelivery(zipcode),
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
                const SizedBox(height: 10),
                _buildSubtotalPrice(),
                Divider(),
                const SizedBox(height: 3),
                _buildTotalPrice(),
                Divider(),
                const SizedBox(height: 3),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed:
                        selectedOption == null
                            ? null
                            : () {
                              _closeMenu();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Compra finalizada com ${selectedOption!["company"]["name"]} - ${selectedOption!["name"]}, valor R\$ ${selectedOption!["price"]}',
                                  ),
                                ),
                              );
                              final user =
                                  Supabase.instance.client.auth.currentUser;
                              if (user == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Usuário não autenticado'),
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
                                        products: cartItems,
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
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: cartItemCount,
      builder: (context, value, _) {
        return IconButton(
          icon: Stack(
            children: [
              const Icon(Icons.shopping_cart, color: Colors.white),
              if (value > 0)
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
                      value.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          onPressed: () async {
            if (isMenuOpen) {
              _closeMenu();
            } else {
              await _loadCartItems();
              _showCartMenu(context);
            }
          },
        );
      },
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

  Widget _buildSubtotalPrice() {
    return Text(
      'Subtotal: R\$ ${_formatCurrency(_calculateSubtotal())}',
      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildTotalPrice() {
    return Column(
      children: [
        //_buildSubtotalPrice(), // Já existente
        const SizedBox(height: 8),
        Text(
          'Taxa de entrega: ${_formatCurrency(deliveryFee)}',
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 8),
        Text(
          'Total: ${_formatCurrency(_calculateTotal())}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
      ],
    );
  }
}

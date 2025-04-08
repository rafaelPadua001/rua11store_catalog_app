import 'package:flutter/material.dart';
import 'package:rua11store_catalog_app/services/delivery_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/cart/cart_repository.dart';
import '../../models/cart.dart';
import '../../data/cart/cart_notifier.dart';
import 'zipcodeInput.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';

class CartMenu extends StatefulWidget {
  const CartMenu({Key? key}) : super(key: key);

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

  @override
  void dispose() {
    _isDisposed = true;
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

      // Apenas chama a função (não tenta receber retorno dela)
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

    final BuildContext? currentContext = context;
    if (currentContext == null) return;

    final item = cartItems[index];
    final itemId = item['id']?.toString();

    if (itemId == null) {
      ScaffoldMessenger.of(
        currentContext,
      ).showSnackBar(const SnackBar(content: Text('ID do item inválido')));
      return;
    }

    // Guarda o estado anterior
    final previousItems = List<Map<String, dynamic>>.from(cartItems);

    // Remove otimista
    if (!_isDisposed) {
      setState(() => cartItems.removeAt(index));
      cartItemCount.value = cartItems.length;
    }

    try {
      await _cartRepository.removeItem(itemId); // <- agora sem atribuir
    } catch (e) {
      // Rollback em caso de erro
      if (!_isDisposed)
        setState(() {
          cartItems = previousItems;
          cartItemCount.value = cartItems.length;
        });
      ScaffoldMessenger.of(currentContext).showSnackBar(
        SnackBar(content: Text('Erro ao remover item: ${e.toString()}')),
      );
    }

    if (!_isDisposed) {
      Navigator.of(currentContext).pop(); // Fecha o menu atual
      await Future.delayed(const Duration(milliseconds: 50));
      if (cartItems.isNotEmpty) {
        _showCartMenu(currentContext); // Reabre o menu com os dados atualizados
      }
    }
  }

  Future<void> _handleCalculateDelivery(
  BuildContext context,
  String zipcode,
) async {
  final service = DeliveryService();

  try {
    final result = await service.calculateDelivery(zipDestiny: zipcode);

    setState(() {
      deliveryOptions = result;
    });

    Navigator.of(context).pop(); // fecha menu atual
    await Future.delayed(Duration(milliseconds: 100));
    if (!_isDisposed) _showCartMenu(context); // reabre com lista atualizada

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Frete calculado com sucesso')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erro ao calcular frete: $e')),
    );
  }
}


  void _showCartMenu(BuildContext context) {
    isMenuOpen = true;

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width - 300,
        80,
        0,
        0,
      ),
      items: [
        PopupMenuItem(
          height: 400,
          child: Container(
            width: 300,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Seu Carrinho',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Chip(
                      backgroundColor: Theme.of(context).primaryColor,
                      label: Text(
                        cartItems.isEmpty
                            ? 'Vazio'
                            : '${cartItems.length} ${cartItems.length == 1 ? 'item' : 'itens'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(),
                if (isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (cartItems.isEmpty)
                  const Center(child: Text('Seu carrinho está vazio'))
                else
                  Column(
                    children: [
                      SizedBox(
                        height: 250,
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: cartItems.length,
                          itemBuilder: (context, index) {
                            final item = cartItems[index];
                            final itemId =
                                item['id']?.toString() ?? index.toString();
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
                                  padding: const EdgeInsets.only(right: 20),
                                  child: const Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                  ),
                                ),
                                onDismissed: (direction) => _removeItem(index),
                                child: ListTile(
                                  leading:
                                      item['image_url'] != null
                                          ? ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Image.network(
                                              imageUrl,
                                              width: 50,
                                              height: 50,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => const Icon(
                                                    Icons.broken_image,
                                                  ),
                                            ),
                                          )
                                          : const Icon(
                                            Icons.image_not_supported,
                                          ),
                                  title: Text(
                                    item['product_name'] ?? 'Produto sem nome',
                                    style: TextStyle(fontSize: 10),
                                  ),
                                  subtitle: Text(
                                    'Qtd: ${item['quantity'] ?? 0}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'R\$ ${(item['price'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
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
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      ZipcodeInputWidget(
                        zipController: _zipController,
                        onSearch:
                            (zipcode) =>
                                _handleCalculateDelivery(context, zipcode),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height:
                            150, // altura definida para evitar erro de layout
                        child: _buildListView(deliveryOptions),
                      ),

                      const SizedBox(height: 16),
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
                                    Navigator.of(context).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Compra finalizada com ${selectedOption!["company"]["name"]} - ${selectedOption!["name"]}, valor R\$ ${selectedOption!["price"].toStringAsFixed(2)}',
                                        ),
                                      ),
                                    );

                                    // TODO: Aqui você pode chamar seu método de checkout passando o selectedOption
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
              ],
            ),
          ),
        ),
      ],
    ).then((_) {
      if (!_isDisposed) {
        setState(() => isMenuOpen = false);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _loadCartItems();
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
            if (isMenuOpen) return;

            await _loadCartItems();
            _showCartMenu(context);
          },
        );
      },
    );
  }

  Widget _buildListView(List result) {
    if (result.isEmpty) {
      return Center(child: Text("nenhum resultado"));
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
            leading: Container(
              width: 40,
              height: 40,
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
                  print(selectedOption);
               
                //Navigator.pop(context, item);
              
            });
          },
          child: Card(
            color: isSelected ? Colors.blue[50] : Colors.white,
            child: ListTile(
              leading: Container(
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

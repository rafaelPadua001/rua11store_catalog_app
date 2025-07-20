import 'package:flutter/material.dart';
import 'package:flutter_spinbox/flutter_spinbox.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:rua11store_catalog_app/controllers/commentsController.dart';
import 'package:rua11store_catalog_app/models/comment.dart';
import 'package:rua11store_catalog_app/screens/payment/checkoutPage.dart';
import 'package:rua11store_catalog_app/widgets/layout/comments/commentBottomSheet.dart';
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
  User? _loggedUser;
  final apiUrl = dotenv.env['API_URL'];
  //final apiUrl = dotenv.env['API_URL_LOCAL'];
  double quantity = 1;
  Map<String, dynamic>? selectedDelivery;
  String? selectedZipCode;
  bool _isAddingToCart = false;
  final bool _isBuying = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLoggedUser();
    });
  }

  Future<void> _loadLoggedUser() async {
    final user = await verifyLogged();
    setState(() {
      _loggedUser = user;
    });
  }

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

  Future<void> _onUpdateComment(Comment comment) async {
    final update = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (_) => CommentBottomSheet(
            userName: comment.userName ?? '',
            avatarUrl: comment.avatar_url ?? '',
            productId: comment.productId,
            comment: comment.comment ?? '',
            commentId: comment.id,
          ),
    );

    if (update != null) {
      setState(() {
        final index = widget.product.comments.indexWhere(
          (c) => c.id == comment.id,
        );
        if (index != -1) {
          widget.product.comments[index] = Comment(
            id: comment.id,
            comment: update['comment'],
            userId: update['user_id'],
            userName: update['user_name'],
            avatar_url: update['avatar_url'],
            productId: update['product_id'],
            status: update['status'],
            createdAt:
                DateTime.tryParse(update['create_at'] ?? '') ?? DateTime.now(),
            updatedAt:
                DateTime.tryParse(update['updated_at'] ?? '') ?? DateTime.now(),
          );
        }
      });
    }
  }

  Future<void> _onRemoveComment(int commentId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Remove comment'),
            content: const Text(
              'Are you sure you want to remove this comment ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Remove'),
              ),
            ],
          ),
    );

    if (shouldDelete == true) {
      final controller = Commentscontroller();
      final response = await controller.deleteComment(commentId);

      if (response) {
        setState(() {
          widget.product.comments.removeWhere((c) => c.id == commentId);
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Removed comment')));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro on remove comment')));
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
      'product_id': widget.product.id,
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
              userName: user.userMetadata?['display_name'] ?? '',
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
            _buildComments(),
          ],
        ),
      ),
      bottomNavigationBar: _buildCardActions(),
    );
  }

  Widget _buildProductImage(apiUrl) {
    return Image.network(widget.product.image, width: 340, fit: BoxFit.cover);
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

                print("RESULTADO RETORNADO DO MODAL: $result");

                if (result != null && result is Map) {
                  final delivery = result['delivery'];
                  final zip = result['zipcode'];

                  if (delivery != null && zip is String) {
                    setState(() {
                      selectedDelivery = delivery;
                      selectedZipCode = zip;
                    });

                    print("🚚 selectedDelivery atualizado: $selectedDelivery");
                  } else {
                    debugPrint('Dados retornados são inválidos');
                  }
                } else {
                  debugPrint('Nenhum resultado selecionado');
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

  Widget _buildComments() {
    final comments = widget.product.comments ?? [];

    if (comments.isEmpty) {
      return Card(
        elevation: 5,
        child: ExpansionTile(
          title: const Text(
            'Comments',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          children: const [
            Padding(
              padding: EdgeInsets.all(12.0),
              child: Text('No comments yet.'),
            ),
          ],
        ),
      );
    }
    return Card(
      elevation: 5,
      child: ExpansionTile(
        title: Text(
          'Comments (${comments.where((c) => c.status == 'ativo').length})',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        children:
            comments.where((comment) => comment.status == 'ativo').map<Widget>((
              comment,
            ) {
              final isOwner =
                  _loggedUser != null && comment.userId == _loggedUser!.id;

              return ListTile(
                leading:
                    comment.avatar_url != null && comment.avatar_url!.isNotEmpty
                        ? CircleAvatar(
                          backgroundImage: NetworkImage(comment.avatar_url!),
                        )
                        : const CircleAvatar(child: Icon(Icons.person)),
                title: Text(comment.userName ?? 'Anonymous'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(comment.comment ?? ''),
                    const SizedBox(height: 8),
                    if (isOwner)
                      Row(
                        children: [
                          TextButton(
                            onPressed: () => _onUpdateComment(comment),
                            child: const Text('Edit'),
                          ),
                          TextButton(
                            onPressed: () => _onRemoveComment(comment.id),
                            child: const Text('Remove'),
                          ),
                        ],
                      ),
                  ],
                ),
                trailing: Text(
                  comment.createdAt != null
                      ? timeago.format(
                        comment.createdAt!.toLocal(),
                        locale: 'pt_br',
                      )
                      : '',
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildCardActions() {
    return Container(
      color: const Color.fromARGB(255, 113, 30, 247),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              IconButton(
                color: Colors.white,
                icon: Icon(Icons.comment),
                tooltip: 'Comment',
                onPressed: () async {
                  final result =
                      await showModalBottomSheet<Map<String, dynamic>>(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                        ),
                        builder:
                            (_) => CommentBottomSheet(
                              userName: 'username',
                              avatarUrl: 'https://example.com/avatar.jpg',
                              productId: widget.product.id,
                            ),
                      );

                  final Map<String, dynamic>? success =
                      result?['success'] as Map<String, dynamic>?;

                  if (success != null) {
                    final Map<String, dynamic>? commentData =
                        success['comment'] as Map<String, dynamic>?;

                    if (commentData != null) {
                      final int id =
                          commentData['id'] is int
                              ? commentData['id']
                              : int.tryParse(commentData['id'].toString()) ?? 0;
                      final String comment = commentData['comment'] ?? '';
                      final String userId = commentData['user_id'] ?? '';
                      final String userName = commentData['user_name'] ?? '';
                      final String avatarUrl = commentData['avatar_url'] ?? '';
                      final int productId =
                          commentData['product_id'] is int
                              ? commentData['product_id']
                              : int.tryParse(
                                    commentData['product_id'].toString(),
                                  ) ??
                                  0;
                      final String status = commentData['status'] ?? 'pendente';
                      final DateTime? createdAt = DateTime.tryParse(
                        commentData['created_at'] ?? '',
                      );
                      final DateTime? updatedAt = DateTime.tryParse(
                        commentData['updated_at'] ?? '',
                      );

                      // Agora você pode atualizar seu estado com o comentário:
                      setState(() {
                        widget.product.comments.add(
                          Comment(
                            id: id,
                            comment: comment,
                            userId: userId,
                            userName: userName,
                            avatar_url: avatarUrl,
                            productId: productId,
                            status: status,
                            createdAt: createdAt,
                            updatedAt: updatedAt,
                          ),
                        );
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success['message'] ??
                                'Comentário salvo com sucesso',
                          ),
                        ),
                      );
                    } else {
                      print(
                        'Erro: comentário não encontrado dentro do success',
                      );
                    }
                  } else {
                    print('Erro: resposta success inválida');
                  }
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
                  key: ValueKey(widget.product.id),
                  min: 1,
                  max:
                      (widget.product.stockQuantity >= 1)
                          ? widget.product.stockQuantity.toDouble()
                          : 1.0,
                  value: quantity,
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
                    labelStyle: TextStyle(color: Colors.white), // label branca
                    filled: true,
                    fillColor: const Color.fromARGB(
                      255,
                      113,
                      30,
                      247,
                    ), // fundo preto
                    border: OutlineInputBorder(),
                  ),
                  textStyle: TextStyle(color: Colors.white), // texto branco
                  iconColor: WidgetStateProperty.all(
                    Colors.white,
                  ), // botões brancos (setas)
                ),
              ),

              SizedBox(width: 2),
              Expanded(
                child: TextButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                    backgroundColor: const Color.fromARGB(255, 113, 30, 247),
                    minimumSize: Size(double.infinity, 25),
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

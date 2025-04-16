import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../controllers/PaymentController.dart';
import '../../models/payment.dart';

class CheckoutPage extends StatefulWidget {
  final String userId;
  final String? zipCode;
  final List<Map> products;
  final Map delivery;

  const CheckoutPage({
    super.key,
    required this.userId,
    required this.products,
    required this.delivery,
    this.zipCode,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String _selectedPayment = 'Crédito'; // valor padrão
  double _subtotal = 0.0;
  double _shipping = 0.0;
  double _total = 0.0;
  late TextEditingController _numberCardController;
  late TextEditingController _nameCardController;
  late TextEditingController _cardExpiryController;
  late TextEditingController _cardCVVController;




  @override
  void initState() {
    super.initState();
      _numberCardController = TextEditingController();
    _nameCardController = TextEditingController();
    _cardExpiryController = TextEditingController();
    _cardCVVController = TextEditingController();

    _subtotal = widget.products.fold<double>(
      0.0,
      (sum, item) => sum + (double.tryParse(item['price'].toString()) ?? 0.0),
    );

    _shipping = double.tryParse(widget.delivery['price'].toString()) ?? 0.0;

    _total = _subtotal + _shipping;
  }

    @override
  void dispose() {
    _numberCardController.dispose();
    _nameCardController.dispose();
    _cardExpiryController.dispose();
    _cardCVVController.dispose();
    super.dispose();
  }

  void _handlePayment() async {
    final convertedProducts =
        widget.products
            .map<Map<String, dynamic>>(
              (item) =>
                  item.map((key, value) => MapEntry(key.toString(), value)),
            )
            .toList();

    final payment = Payment(
      zipCode: widget.zipCode!,
      address: 'qms 10 rua 11 casa 20',
      paymentType: _selectedPayment,
      subtotal: _subtotal,
      shipping: _shipping,
      total: _total,
      products: convertedProducts,
      numberCard: _selectedPayment != 'Pix' ? _numberCardController.text : null,
      nameCard: _selectedPayment != 'Pix' ? _nameCardController.text : null,
      expiry: _selectedPayment != 'Pix' ? _cardExpiryController.text : null,
      cvv: _selectedPayment != 'Pix' ? _cardCVVController.text : null,
    );

    final controller = PaymentController();
    final success = await controller.sendPayment(payment);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pagamento enviado com sucesso!')),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Erro ao enviar pagamento')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProductsList(), // Certifique-se que aqui não tem ListView com scroll
                    _buildAddressCard(context),
                    _buildPaymentCard(context),
                    _buildTotalCard(context),
                    const SizedBox(height: 16),
                    _buildElevatedButton(), // Botão azul grande
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductsList() {
    final apiUrl = dotenv.env['API_URL'] ?? '';
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children:
            widget.products.map((p) {
              final imageUrl = p['image'];
              final name = p['name'];
              final price = p['price'];

              return Card(
                margin: const EdgeInsets.all(12.0),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child:
                            imageUrl != null
                                ? Image.network(
                                  apiUrl + imageUrl,
                                  height: 80,
                                  width: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stackTrace) =>
                                          const Icon(
                                            Icons.broken_image,
                                            size: 80,
                                          ),
                                )
                                : const Icon(
                                  Icons.image_not_supported,
                                  size: 80,
                                ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name ?? 'Sem nome',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'R\$ $price',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          print('Remover ${p['name']}');
                          // Lógica para remover item
                        },
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildAddressCard(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Delivery to Address',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('John Doe'),
                    Text('123 Main Street'),
                    Text('Springfield, IL 62791'),
                    SizedBox(height: 6),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  // lógica de alterar endereço
                },
                child: const Text('Change'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentCard(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Payment Method',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              RadioListTile<String>(
                title: const Text('Cartão de Crédito'),
                value: 'credit',
                groupValue: _selectedPayment,
                onChanged: (value) {
                  setState(() {
                    _selectedPayment = value!;
                  });
                },
              ),
              RadioListTile<String>(
                title: const Text('Cartão de Débito'),
                value: 'debit',
                groupValue: _selectedPayment,
                onChanged: (value) {
                  setState(() {
                    _selectedPayment = value!;
                  });
                },
              ),
              RadioListTile<String>(
                title: const Text('Pix'),
                value: 'pix',
                groupValue: _selectedPayment,
                onChanged: (value) {
                  setState(() {
                    _selectedPayment = value!;
                  });
                },
              ),

              const SizedBox(height: 16),

              if (_selectedPayment == 'credit' || _selectedPayment == 'debit')
                _buildCardPaymentForm()
              else if (_selectedPayment == 'pix')
                _buildPixInfo(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardPaymentForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _numberCardController,
          decoration: InputDecoration(labelText: 'Número do Cartão'),
        ),
        TextField(
          controller: _nameCardController,
          decoration: InputDecoration(labelText: 'Nome no Cartão'),
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _cardExpiryController,
                decoration: InputDecoration(labelText: 'Validade'),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              
              child: TextField(controller: _cardCVVController, decoration: InputDecoration(labelText: 'CVV')),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPixInfo() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Você selecionou pagamento via pix"),
        Text('A chave pix será exibida após o pedido'),
      ],
    );
  }

  Widget _buildTotalCard(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Order Summary',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text('Subtotal: R\$ ${_subtotal.toStringAsFixed(2)}'),
              Text('Shipping: R\$ ${_shipping}'),
              const SizedBox(height: 8),
              Text(
                'Total: R\$ ${_total}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildElevatedButton() {
    return SizedBox(
      width: double.infinity, // ocupa toda a largura disponível
      height: 60, // opcional, define uma altura padrão
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue, // cor azul
          foregroundColor: Colors.white, // texto branco
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              8,
            ), // bordas arredondadas (opcional)
          ),
        ),
        onPressed: () {
          _handlePayment();
          // ScaffoldMessenger.of(context).showSnackBar(
          //   const SnackBar(content: Text('Estamos trabalhando nisso')),
          // );
        },
        child: const Text(
          'Place Order Now',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

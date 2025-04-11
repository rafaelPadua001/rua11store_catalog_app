import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CheckoutPage extends StatefulWidget {
  final String userId;
  final List<Map> products;
  final Map delivery;

  const CheckoutPage({
    super.key,
    required this.userId,
    required this.products,
    required this.delivery,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String _selectedPayment = 'Crédito'; // valor padrão

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProductsList(),
              _buildAddressCard(context),
              _buildPaymentCard(context),
              _buildTotalCard(context),
              const SizedBox(height: 16),
              _buildElevatedButton(),
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
                value: 'Crédito',
                groupValue: _selectedPayment,
                onChanged: (value) {
                  setState(() {
                    _selectedPayment = value!;
                  });
                },
              ),
              RadioListTile<String>(
                title: const Text('Cartão de Débito'),
                value: 'Débito',
                groupValue: _selectedPayment,
                onChanged: (value) {
                  setState(() {
                    _selectedPayment = value!;
                  });
                },
              ),
              RadioListTile<String>(
                title: const Text('Pix'),
                value: 'Pix',
                groupValue: _selectedPayment,
                onChanged: (value) {
                  setState(() {
                    _selectedPayment = value!;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTotalCard(BuildContext context) {
    final subtotal = widget.products.fold<double>(
      0.0,
      (sum, item) => sum + (double.tryParse(item['price'].toString()) ?? 0.0),
    );

    final shipping =
        double.tryParse(widget.delivery['price'].toString()) ?? 0.0;

    final total = subtotal + shipping;

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
              Text('Subtotal: R\$ ${subtotal.toStringAsFixed(2)}'),
              Text('Shipping: R\$ ${shipping}'),
              const SizedBox(height: 8),
              Text(
                'Total: R\$ ${total}',
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Estamos trabalhando nisso')),
          );
        },
        child: const Text(
          'Place Order Now',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

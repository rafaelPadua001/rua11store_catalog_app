import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../models/product.dart';
import '../../widgets/layout/bottomSheePaget.dart';

class ProductScreen extends StatefulWidget {
  final Product product;
  // final BottomSheetPage _bottomSheetPage = BottomSheetPage();
  

  ProductScreen({Key? key, required this.product}) : super(key: key);
  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final apiUrl = dotenv.env['API_URL'];
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product.name), // usando o nome do produto
      ),
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
      // height: 350,
      width: 340,
      fit: BoxFit.cover,
    );
  }

  Widget _buildPriceCard() {
    return Card(
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Price: R\$ ${double.parse(widget.product.price).toStringAsFixed(2)}',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)
              ),
            ),
          ],
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
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween, // alinhamento horizontal
          children: [
            Expanded(
              // garante que o texto ocupe o espaço necessário
              child: Text(
                'Delivery Price: R\$ ${double.parse(widget.product.price).toStringAsFixed(2)}',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: Icon(Icons.arrow_forward_ios),
              iconSize: 15,
              tooltip: 'Mais detalhes',
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  builder: (context) => BottomSheetPage(),
                );
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
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Description: ${widget.product.description}',
                style: TextStyle(fontSize: 12)
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardActions() {
    return Container(
      color: Colors.deepPurple, // Aqui você define o background da área toda
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Botão de comentário com fundo
              Container(
                decoration: BoxDecoration(
                  // color: Colors.blue.shade100,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
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
              ),
              SizedBox(width: 8),

              // Botão de carrinho com fundo
              Container(
                decoration: BoxDecoration(
                  // color: Colors.red.shade100,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  color: Colors.white,
                  icon: Icon(Icons.add_shopping_cart_sharp),
                  tooltip: 'cart',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Botão adicionar ao carrinho ainda não está pronto',
                        ),
                      ),
                    );
                  },
                ),
              ),
              // SizedBox(width: 8),

              // Botão Buy Now
              Expanded(
                child: TextButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                    backgroundColor: Colors.deepPurple,
                    minimumSize: Size(double.infinity, 50),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Botão comprar ainda não está pronto'),
                      ),
                    );
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

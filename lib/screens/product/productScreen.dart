import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../models/product.dart';

class ProductScreen extends StatefulWidget{
  final Product product;
 

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
      body: Column(
        children: [
          _buildProductImage(apiUrl),
          Image.network(widget.product.image),
          const SizedBox(height: 16),
          Text('Preço: R\$ ${double.parse(widget.product.price).toStringAsFixed(2)}'),

          const SizedBox(height: 8),
          Text('Descrição: ${widget.product.description}'),
        ],
      ),
    );
  }

  Widget _buildProductImage(apiUrl){
    return Image.network(apiUrl+widget.product.image);
  }
}

import 'package:flutter/material.dart';
import '../../models/product.dart';

class ProductScreen extends StatefulWidget{
  final Product product;

  const ProductScreen({Key? key, required this.product}) : super(key: key);
  @override 
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product.name), // usando o nome do produto
      ),
      body: Column(
        children: [
          Image.network(widget.product.image),
          const SizedBox(height: 16),
          Text('Preço: R\$ ${double.parse(widget.product.price).toStringAsFixed(2)}'),

          const SizedBox(height: 8),
          Text('Descrição: ${widget.product.description}'),
        ],
      ),
    );
  }
}

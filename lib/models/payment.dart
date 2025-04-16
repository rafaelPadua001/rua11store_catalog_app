class Payment {
  final String zipCode;
   final String address;
  final String paymentType;
  final double subtotal;
  final double shipping;
  final double total;
  final List<Map<String, dynamic>> products;

  final String? numberCard;
  final String? nameCard;
  final String? expiry;
  final String? cvv;

  Payment({
    required this.zipCode,
    required this.address,
    required this.paymentType,
    required this.subtotal,
    required this.shipping,
    required this.total,
    required this.products,
    this.numberCard,
    this.nameCard,
    this.expiry,
    this.cvv,

  });

  Map<String, dynamic> toJson(){
      return {
      'zipCode': zipCode,
      'address': address,
      'paymentType': paymentType,
      'subtotal': subtotal.toStringAsFixed(2),
      'frete': shipping.toStringAsFixed(2),
      'total': total.toStringAsFixed(2),
      'products': products,
      if (paymentType == 'Crédito' || paymentType == 'Débito') ...{
        'cartao': {
          'numero': numberCard,
          'nome': nameCard,
          'validade': expiry,
          'cvv': cvv,
        }
      }
    };
  }

}
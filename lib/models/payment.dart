class Payment {
  final String zipCode;
  final String userEmail;
  final String userId;
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
  final String? cardToken;
  final int? installments;
  final String cpf;

  Payment({
    required this.zipCode,
    required this.userEmail,
    required this.userId,
    required this.address,
    required this.paymentType,
    required this.subtotal,
    required this.shipping,
    required this.total,
    required this.products,
    required this.cpf,
    this.numberCard,
    this.nameCard,
    this.expiry,
    this.cvv,
    this.cardToken,
    this.installments,
  });

  Map<String, dynamic> toJson() {
    return {
      'card_token': cardToken,
      'installments': installments,
      'zipCode': zipCode,
      'payer_email': userEmail,
      'userId': userId,
      'payer_cpf': cpf,
      'address': address,
      'paymentType': paymentType,
      'subtotal': subtotal.toStringAsFixed(2),
      'frete': shipping.toStringAsFixed(2),
      'total': total.toStringAsFixed(2),
      'products': products,
      if(cardToken != null) 'card_token' : cardToken,
      if (paymentType == 'Crédito' || paymentType == 'Débito') ...{
        'cartao': {
          'numero': numberCard,
          'nome': nameCard,
          'validade': expiry,
          'cvv': cvv,
        },
      },
    };
  }
}

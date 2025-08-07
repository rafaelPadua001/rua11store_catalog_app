class Payment {
  final String zipCode;
  final String userEmail;
  final String userName;
  final String userId;
  final String? paymentMethodId;
  final Map<String, dynamic> address; // <-- aqui
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
  final double? couponAmount;
  final String? couponCode;
  final int? installments;
  final String cpf;

  Payment({
    required this.zipCode,
    required this.userEmail,
    required this.userName,
    required this.userId,
    required this.paymentMethodId,
    required this.address, // <-- aqui
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
    this.couponAmount,
    this.couponCode,
  });

  Map<String, dynamic> toJson() {
    return {
      'card_token': cardToken,
      'installments': installments,
      'zipCode': zipCode,
      'payer_email': userEmail,
      'payer_name': userName,
      'userId': userId,
      'payment_method_id': paymentMethodId,
      'payer_cpf': cpf,
      'address': address, // <-- aqui
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
        },
      },
      'coupon_amount': couponAmount,
      'coupon_code': couponCode,
    };
  }
}

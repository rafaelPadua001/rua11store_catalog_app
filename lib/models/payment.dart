class Payment {
  final String zipCode;
  final String userEmail;
  final String userName;
  final String userId;
  final String? paymentMethodId;
  final Map<String, dynamic>? address;
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
    this.paymentMethodId,
    this.address,
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

  /// Envia para backend
  Map<String, dynamic> toJson() {
    final map = {
      'card_token': cardToken ?? '',
      'installments': installments ?? 1,
      'zipCode': zipCode,
      'payer_email': userEmail,
      'payer_name': userName,
      'userId': userId,
      'payment_method_id': paymentMethodId ?? '',
      'payer_cpf': cpf,
      'address': address ?? {},
      'paymentType': paymentType,
      'subtotal': subtotal.toStringAsFixed(2),
      'frete': shipping.toStringAsFixed(2),
      'total': total.toStringAsFixed(2),
      'products': products,
      'coupon_amount': couponAmount ?? 0,
      'coupon_code': couponCode ?? '',
    };

    // Sempre adiciona cartao se tiver dados
    if (numberCard != null ||
        nameCard != null ||
        expiry != null ||
        cvv != null) {
      map['cartao'] = {
        'numero': numberCard ?? '',
        'nome': nameCard ?? '',
        'validade': expiry ?? '',
        'cvv': cvv ?? '',
      };
    }

    return map;
  }

  /// Constrói a partir do backend
  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      zipCode: json['zipCode'] ?? '',
      userEmail: json['payer_email'] ?? '',
      userName: json['payer_name'] ?? '',
      userId: json['userId'] ?? '',
      paymentMethodId: json['payment_method_id'],
      address: (json['address'] as Map<String, dynamic>?) ?? {},
      paymentType: json['paymentType'] ?? '',
      subtotal: double.tryParse(json['subtotal'].toString()) ?? 0.0,
      shipping: double.tryParse(json['frete'].toString()) ?? 0.0,
      total: double.tryParse(json['total'].toString()) ?? 0.0,
      products:
          (json['products'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [],
      cpf: json['payer_cpf'] ?? '',
      numberCard: json['cartao']?['numero'],
      nameCard: json['cartao']?['nome'],
      expiry: json['cartao']?['validade'],
      cvv: json['cartao']?['cvv'],
      cardToken: json['card_token'],
      installments: json['installments'],
      couponAmount:
          (json['coupon_amount'] != null)
              ? double.tryParse(json['coupon_amount'].toString())
              : null,
      couponCode: json['coupon_code'],
    );
  }
}

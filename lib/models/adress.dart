class Address {
  final int? id;
  final String? userId;
  // final int? productId;
  final String recipientName;
  final String street;
  final String number;
  final String complement;
  final String city;
  final String state;
  final String zipCode;
  final String country;
  final String bairro;
  final String phone;

  Address({
    this.id,
    this.userId,
    // this.productId,
    required this.recipientName,
    required this.street,
    required this.number,
    required this.complement,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.country,
    required this.bairro,
    required this.phone,
  });

  Map<String, dynamic> toMap() {
    return {
      'recipient_name': recipientName,
      'street': street,
      'number': number,
      'complement': complement,
      'bairro': bairro,
      'city': city,
      'state': state,
      'zip_code': zipCode,
      'country': country,
      'phone': phone,
    };
  }

  //convert to json
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      //  'product_id': productId,
      'recipient_name': recipientName,
      'street': street,
      'number': number,
      'complement': complement,
      'city': city,
      'state': state,
      'zip_code': zipCode,
      'country': country,
      'bairro': bairro,
      'phone': phone,
    };
  }

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'],
      userId: json['user_id'],
      // productId: json['product_id'],
      recipientName: json['recipient_name'] ?? '',
      street: json['street'] ?? '',
      number: json['number'] ?? '',
      complement: json['complement'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      zipCode: json['zip_code'] ?? '',
      country: json['country'] ?? '',
      bairro: json['bairro'] ?? '',
      phone: json['phone'] ?? '',
    );
  }
}

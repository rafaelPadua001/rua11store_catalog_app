import 'order_items.dart';

class Order {
  final int orderId;
  final String userId;
  final String status;
  final String orderDate;
  final double orderTotal;
  final int paymentId;
  final String shipmentInfo;
  final String? melhorEnvioId;
  final List<OrderItem> items;
  final String? deliveryId;

  Order({
    required this.orderId,
    required this.userId,
    required this.status,
    required this.orderDate,
    required this.orderTotal,
    required this.paymentId,
    required this.shipmentInfo,
    required this.items,
    this.deliveryId,
    this.melhorEnvioId,    
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      orderId: json['id'],
      userId: json['user_id'],
      status: json['status'],
      orderDate: json['order_date'],
      orderTotal: (json['total_amount'] as num).toDouble(),
      paymentId: json['payment_id'],
      melhorEnvioId: json['melhorenvio_id'],
      shipmentInfo: json['shipment_info'],
      deliveryId: json['delivery_id']?.toString(),
      items: (json['products'] as List<dynamic>)
          .map((item) => OrderItem.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': orderId,
      'user_id': userId,
      'status': status,
      'order_date': orderDate,
      'total_amount': orderTotal,
      'payment_id': paymentId,
      'melhorenvio_id': melhorEnvioId,
      'shipment_info': shipmentInfo,
      'delivery_id': deliveryId,
      'products': items.map((item) => item.toJson()).toList(),
    };
  }
}

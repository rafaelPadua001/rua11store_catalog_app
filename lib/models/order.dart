import 'order_items.dart';

class Order {
  final int orderId;
  final String userId;
  final String status;
  final String orderDate;
  final double orderTotal;
  final int paymentId;
  final String shipmentInfo;
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
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      orderId: json['order_id'],
      userId: json['user_id'],
      status: json['status'],
      orderDate: json['order_date'],
      orderTotal: (json['order_total'] as num).toDouble(),
      paymentId: json['payment_id'],
      shipmentInfo: json['shipment_info'],
      deliveryId: json['delivery_id'],
      items:
          (json['items'] as List<dynamic>)
              .map((item) => OrderItem.fromJson(item))
              .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'user_id': userId,
      'status': status,
      'order_date': orderDate,
      'order_total': orderTotal,
      'payment_id': paymentId,
      'shipment_info': shipmentInfo,
      'delivery_id': deliveryId,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

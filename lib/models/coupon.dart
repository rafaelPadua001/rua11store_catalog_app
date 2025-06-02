class Coupon {
  final String id;
  final String code;
  final double discount;
  final String title;
  final DateTime startDate;
  final DateTime endDate;

  Coupon({
    required this.id,
    required this.code,
    required this.discount,
    required this.title,
    required this.startDate,
    required this.endDate,
  });

  factory Coupon.fromJson(Map<String, dynamic> json) {
    return Coupon(
      id: json['id'].toString(),
      code: json['code'],
      discount: double.tryParse(json['discount'].toString()) ?? 0.0,
      title: json['title'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'discount': discount,
      'title': title,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
    };
  }
}

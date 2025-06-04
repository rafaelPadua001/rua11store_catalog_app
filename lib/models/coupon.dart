class Coupon {
  final int id;
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
      id: int.tryParse(json['id'].toString()) ?? 0,
      code: json['code'].toString(),
      discount: double.tryParse(json['discount'].toString()) ?? 0.0,
      title: json['title'].toString(),
      startDate: DateTime.parse(json['start_date'].toString()),
      endDate: DateTime.parse(json['end_date'].toString()),
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

class EarningModel {
  const EarningModel({
    required this.id,
    required this.amount,
    required this.type,
    required this.date,
    required this.status,
  });

  final String id;
  final double amount;
  final String type;
  final DateTime date;
  final String status;

  factory EarningModel.fromJson(Map<String, dynamic> json) {
    return EarningModel(
      id: json['id']?.toString() ?? '',
      amount: _asDouble(json['amount']),
      type: json['type']?.toString() ?? '',
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      status: json['status']?.toString() ?? '',
    );
  }

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

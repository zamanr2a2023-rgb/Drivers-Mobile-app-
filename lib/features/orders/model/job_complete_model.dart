/// Response from `POST /drivers/jobs/:jobId/complete`.
class JobCompleteResult {
  const JobCompleteResult({
    required this.message,
    this.summary,
  });

  final String message;
  final JobCompleteSummary? summary;

  factory JobCompleteResult.fromJson(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is! Map) {
      throw const FormatException('Invalid complete job response');
    }
    final map = Map<String, dynamic>.from(data);
    final summaryRaw = map['summary'];

    return JobCompleteResult(
      message: map['message']?.toString() ?? 'Delivery completed',
      summary: summaryRaw is Map
          ? JobCompleteSummary.fromJson(Map<String, dynamic>.from(summaryRaw))
          : null,
    );
  }
}

class JobCompleteSummary {
  const JobCompleteSummary({
    required this.earningsAdded,
    required this.deliveryFee,
    required this.tipAmount,
    required this.todayTotalEarnings,
    required this.distanceKm,
    required this.durationMin,
    required this.paymentMethod,
    this.cashCollected,
    this.ageVerified = false,
  });

  final double earningsAdded;
  final double deliveryFee;
  final double tipAmount;
  final double todayTotalEarnings;
  final double distanceKm;
  final int durationMin;
  final String paymentMethod;
  final double? cashCollected;
  final bool ageVerified;

  factory JobCompleteSummary.fromJson(Map<String, dynamic> json) {
    return JobCompleteSummary(
      earningsAdded: _asDouble(json['earningsAdded']),
      deliveryFee: _asDouble(json['deliveryFee']),
      tipAmount: _asDouble(json['tipAmount']),
      todayTotalEarnings: _asDouble(json['todayTotalEarnings']),
      distanceKm: _asDouble(json['distanceKm']),
      durationMin: _asInt(json['durationMin']),
      paymentMethod: json['paymentMethod']?.toString() ?? '',
      cashCollected: json['cashCollected'] == null
          ? null
          : _asDouble(json['cashCollected']),
      ageVerified: json['ageVerified'] == true,
    );
  }

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

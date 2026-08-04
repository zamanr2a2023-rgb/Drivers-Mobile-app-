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
    this.deliveryType,
    this.verification,
    this.secureProof,
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
  final String? deliveryType;
  final String? verification;
  final String? secureProof;

  String get earningsAddedLabel => earningsAdded.toStringAsFixed(3);

  String get tipAmountLabel => tipAmount.toStringAsFixed(3);

  String get distanceLabel {
    final value = distanceKm;
    final text = value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
    return '$text km';
  }

  String get durationLabel {
    // Some payloads send seconds under durationMin; keep display readable.
    final minutes =
        durationMin >= 1000 ? (durationMin / 60).round() : durationMin;
    return '$minutes min';
  }

  String get deliveryTypeLabel {
    final raw = deliveryType?.trim();
    if (raw == null || raw.isEmpty) return '—';
    return raw.replaceAll('_', ' · ').replaceAll('-', ' · ');
  }

  factory JobCompleteSummary.fromJson(Map<String, dynamic> json) {
    return JobCompleteSummary(
      earningsAdded: _asDouble(json['earningsAdded']),
      deliveryFee: _asDouble(json['deliveryFee']),
      tipAmount: _asDouble(json['tipAmount']),
      todayTotalEarnings: _asDouble(json['todayTotalEarnings']),
      distanceKm: _asDouble(json['distanceKm']),
      durationMin: _asInt(json['durationMin']),
      paymentMethod: json['paymentMethod']?.toString() ?? '',
      cashCollected: _asNullableDouble(json['cashCollected']),
      ageVerified: json['ageVerified'] == true,
      deliveryType: json['deliveryType']?.toString(),
      verification: json['verification']?.toString(),
      secureProof: json['secureProof']?.toString(),
    );
  }

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is bool) return value ? 1 : 0;
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double? _asNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value ? 1 : 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

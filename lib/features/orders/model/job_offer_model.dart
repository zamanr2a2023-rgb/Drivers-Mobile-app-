class JobOfferModel {
  const JobOfferModel({
    required this.id,
    required this.status,
    required this.orderNumber,
    required this.vendorName,
    required this.pickupArea,
    required this.dropoffArea,
    required this.customerName,
    required this.paymentMethod,
    required this.driverEarnings,
    required this.totalAmount,
    required this.tipAmount,
    required this.distanceKm,
    required this.durationMin,
    required this.category,
    this.expiresAt,
  });

  final String id;
  final String status;
  final String orderNumber;
  final String vendorName;
  final String pickupArea;
  final String dropoffArea;
  final String customerName;
  final String paymentMethod;
  final double driverEarnings;
  final double totalAmount;
  final double tipAmount;
  final double distanceKm;
  final int durationMin;
  final String category;
  final DateTime? expiresAt;

  bool get isCash =>
      paymentMethod.toUpperCase() == 'CASH' ||
      paymentMethod.toUpperCase() == 'POD';

  String get earningsLabel => 'BHD ${driverEarnings.toStringAsFixed(3)}';

  String get cashCollectLabel =>
      'Hand the order, collect BHD ${totalAmount.toStringAsFixed(3)}';

  String get distanceLabel => '${_trimNumber(distanceKm)} km';

  String get etaCategoryLabel {
    final parts = <String>[];
    if (durationMin > 0) parts.add('~$durationMin min');
    if (category.trim().isNotEmpty) parts.add(category.trim());
    return parts.isEmpty ? '' : parts.join(' · ');
  }

  String get pickupSubtitle {
    final area = pickupArea.trim().isNotEmpty ? pickupArea.trim() : 'Pickup';
    return 'Pickup · $area';
  }

  String get dropoffSubtitle {
    final area = dropoffArea.trim().isNotEmpty ? dropoffArea.trim() : 'Drop-off';
    if (distanceKm > 0) {
      return 'Drop-off · $area · ${_trimNumber(distanceKm)} km';
    }
    return 'Drop-off · $area';
  }

  String get timerLabel {
    final expires = expiresAt;
    if (expires == null) return '0:30';
    final remaining = expires.difference(DateTime.now());
    if (remaining.isNegative) return '0:00';
    final totalSeconds = remaining.inSeconds;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  factory JobOfferModel.fromJson(Map<String, dynamic> json) {
    final vendor = _asMap(json['vendor']);
    final pickup = _asMap(json['pickup'] ?? json['pickupLocation']);
    final dropoff = _asMap(json['dropoff'] ?? json['dropoffLocation']);
    final customer = _asMap(json['customer']);

    final vendorName = _firstNonEmpty([
      json['vendorName'],
      vendor?['name'],
      vendor?['businessName'],
    ]);

    final pickupArea = _firstNonEmpty([
      json['pickupArea'],
      pickup?['area'],
      pickup?['zone'],
      pickup?['district'],
      pickup?['address'],
      json['pickupAddress'],
    ]);

    final dropoffArea = _firstNonEmpty([
      json['dropoffArea'],
      dropoff?['area'],
      dropoff?['zone'],
      dropoff?['district'],
      dropoff?['address'],
      json['dropoffAddress'],
    ]);

    final customerName = _firstNonEmpty([
      json['customerName'],
      customer?['name'],
      customer?['fullName'],
    ]);

    return JobOfferModel(
      id: json['id']?.toString() ?? json['jobId']?.toString() ?? '',
      status: json['status']?.toString() ?? 'OFFERED',
      orderNumber: json['orderNumber']?.toString() ??
          json['orderId']?.toString() ??
          '',
      vendorName: vendorName.isEmpty ? 'Vendor' : vendorName,
      pickupArea: pickupArea,
      dropoffArea: dropoffArea,
      customerName: customerName.isEmpty ? 'Customer' : customerName,
      paymentMethod: json['paymentMethod']?.toString() ??
          json['paymentType']?.toString() ??
          '',
      driverEarnings: _asDouble(
        json['driverEarnings'] ?? json['earnings'] ?? json['payout'],
      ),
      totalAmount: _asDouble(
        json['totalAmount'] ?? json['cashToCollect'] ?? json['orderTotal'],
      ),
      tipAmount: _asDouble(json['tipAmount'] ?? json['tip']),
      distanceKm: _asDouble(
        json['distanceKm'] ?? json['distance'] ?? json['tripDistanceKm'],
      ),
      durationMin: _asInt(
        json['durationMin'] ??
            json['estimatedDurationMin'] ??
            json['etaMin'],
      ),
      category: _firstNonEmpty([
        json['category'],
        json['orderCategory'],
        json['deliveryType'],
      ]),
      expiresAt: _parseDate(
        json['expiresAt'] ??
            json['offerExpiresAt'] ??
            json['dispatchOfferExpiresAt'],
      ),
    );
  }

  static List<JobOfferModel> listFromResponse(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => JobOfferModel.fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false);
    }
    if (data is Map) {
      final offers = data['offers'] ?? data['jobs'] ?? data['items'];
      if (offers is List) {
        return offers
            .whereType<Map>()
            .map(
              (item) => JobOfferModel.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList(growable: false);
      }
    }
    return const [];
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static String _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
    }
    return '';
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

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  static String _trimNumber(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }
}

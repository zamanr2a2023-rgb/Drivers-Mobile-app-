class DriverVehicleModel {
  const DriverVehicleModel({
    required this.id,
    required this.driverId,
    required this.vehicleType,
    this.make,
    this.model,
    this.year,
    this.color,
    this.plateNumber,
    this.frontPhotoUrl,
    this.backPhotoUrl,
    this.sidePhotoUrl,
    this.interiorPhotoUrl,
    this.insuranceExpiryDate,
  });

  final String id;
  final String driverId;
  final String vehicleType;
  final String? make;
  final String? model;
  final int? year;
  final String? color;
  final String? plateNumber;
  final String? frontPhotoUrl;
  final String? backPhotoUrl;
  final String? sidePhotoUrl;
  final String? interiorPhotoUrl;
  final String? insuranceExpiryDate;

  /// UI index: 0 = Car, 1 = Motorcycle.
  int get vehicleTypeIndex {
    switch (vehicleType.trim().toUpperCase()) {
      case 'BIKE':
      case 'MOTORCYCLE':
      case 'SCOOTER':
        return 1;
      case 'CAR':
      case 'VAN':
      default:
        return 0;
    }
  }

  bool get hasFrontPhoto => _hasUrl(frontPhotoUrl);
  bool get hasBackPhoto => _hasUrl(backPhotoUrl);
  bool get hasSidePhoto => _hasUrl(sidePhotoUrl);
  bool get hasInteriorPhoto => _hasUrl(interiorPhotoUrl);

  /// Formats API ISO date to DD / MM / YYYY for the form field.
  String get insuranceExpiryDisplay {
    final raw = insuranceExpiryDate?.trim();
    if (raw == null || raw.isEmpty) return '';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    final d = parsed.day.toString().padLeft(2, '0');
    final m = parsed.month.toString().padLeft(2, '0');
    final y = parsed.year.toString();
    return '$d / $m / $y';
  }

  factory DriverVehicleModel.fromJson(Map<String, dynamic> json) {
    return DriverVehicleModel(
      id: json['id']?.toString() ?? '',
      driverId: json['driverId']?.toString() ?? '',
      vehicleType: json['vehicleType']?.toString() ?? '',
      make: _nullableString(json['make']),
      model: _nullableString(json['model']),
      year: _asInt(json['year']),
      color: _nullableString(json['color']),
      plateNumber: _nullableString(json['plateNumber']),
      frontPhotoUrl: _nullableString(json['frontPhotoUrl']),
      backPhotoUrl: _nullableString(json['backPhotoUrl']),
      sidePhotoUrl: _nullableString(json['sidePhotoUrl']),
      interiorPhotoUrl: _nullableString(json['interiorPhotoUrl']),
      insuranceExpiryDate: _nullableString(json['insuranceExpiryDate']),
    );
  }

  static String? _nullableString(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty || text.toLowerCase() == 'null') {
      return null;
    }
    return text;
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static bool _hasUrl(String? url) {
    final value = url?.trim() ?? '';
    return value.isNotEmpty;
  }
}

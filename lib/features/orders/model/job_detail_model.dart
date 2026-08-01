import 'package:yjeek_driver/features/orders/model/contact_attempts_model.dart';

/// Full job payload from `GET /drivers/jobs/:jobId`.
class JobDetailModel {
  const JobDetailModel({
    required this.id,
    required this.status,
    required this.driverEarnings,
    required this.distanceKm,
    required this.estimatedDurationMin,
    required this.progressLabel,
    required this.order,
    this.pickupPhotoUrl,
    this.deliveryPhotoUrl,
    this.cashCollectedAmount,
    this.contactAttempts,
  });

  final String id;
  final String status;
  final double driverEarnings;
  final double distanceKm;
  final int estimatedDurationMin;
  final String progressLabel;
  final JobDetailOrder order;
  final String? pickupPhotoUrl;
  final String? deliveryPhotoUrl;
  final double? cashCollectedAmount;
  final ContactAttemptsResult? contactAttempts;

  bool get requiresCashCollection => order.requiresCashCollection;

  String get distanceEtaLabel {
    final parts = <String>[];
    if (distanceKm > 0) {
      final km = distanceKm == distanceKm.roundToDouble()
          ? distanceKm.toStringAsFixed(1)
          : distanceKm.toStringAsFixed(1);
      parts.add('$km km');
    }
    if (estimatedDurationMin > 0) {
      parts.add('~$estimatedDurationMin min');
    }
    if (parts.isEmpty) {
      final label = progressLabel.trim();
      return label.isNotEmpty ? label : '—';
    }
    return parts.join(' · ');
  }

  factory JobDetailModel.fromJson(Map<String, dynamic> json) {
    final orderRaw = json['order'];
    final orderMap = orderRaw is Map
        ? Map<String, dynamic>.from(orderRaw)
        : <String, dynamic>{};
    final contactRaw = json['contactAttempts'];

    return JobDetailModel(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      driverEarnings: _asDouble(json['driverEarnings']),
      distanceKm: _asDouble(json['distanceKm']),
      estimatedDurationMin: _asInt(json['estimatedDurationMin']),
      progressLabel: json['progressLabel']?.toString() ?? '',
      order: JobDetailOrder.fromJson(orderMap),
      pickupPhotoUrl: _nullableString(json['pickupPhotoUrl']),
      deliveryPhotoUrl: _nullableString(json['deliveryPhotoUrl']),
      cashCollectedAmount: json['cashCollectedAmount'] == null
          ? null
          : _asDouble(json['cashCollectedAmount']),
      contactAttempts: contactRaw is Map
          ? ContactAttemptsResult.fromData(
              Map<String, dynamic>.from(contactRaw),
            )
          : null,
    );
  }

  static String? _nullableString(dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty || text.toLowerCase() == 'null') return null;
    return text;
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

class JobDetailOrder {
  const JobDetailOrder({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.fulfillmentType,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.totalAmount,
    required this.requiresCashCollection,
    required this.cashToCollectAmount,
    required this.tipAmount,
    required this.vendor,
    required this.address,
    required this.customer,
    required this.items,
    this.windowStartAt,
    this.windowEndAt,
    this.scheduledAt,
    this.kitchenNote,
  });

  final String id;
  final String orderNumber;
  final String status;
  final String fulfillmentType;
  final String paymentMethod;
  final String paymentStatus;
  final double totalAmount;
  final bool requiresCashCollection;
  final double cashToCollectAmount;
  final double tipAmount;
  final JobDetailVendor vendor;
  final JobDetailAddress address;
  final JobDetailCustomer customer;
  final List<JobDetailItem> items;
  final DateTime? windowStartAt;
  final DateTime? windowEndAt;
  final DateTime? scheduledAt;
  final String? kitchenNote;

  String get displayOrderNumber {
    var number = orderNumber.trim();
    if (number.isEmpty) return '';
    if (!number.startsWith('#')) number = '#$number';
    return number;
  }

  String get windowLabel {
    final start = windowStartAt?.toLocal();
    final end = windowEndAt?.toLocal();
    if (start != null && end != null) {
      final day = _dayLabel(start);
      return '$day · ${_hourLabel(start)}–${_hourLabel(end)}';
    }
    if (scheduledAt != null) {
      final at = scheduledAt!.toLocal();
      return '${_dayLabel(at)} · ${_hourLabel(at)}';
    }
    if (fulfillmentType.toUpperCase() == 'ON_DEMAND') {
      return 'On demand';
    }
    return '—';
  }

  String get cashCollectLabel {
    final amount = cashToCollectAmount > 0 ? cashToCollectAmount : totalAmount;
    return 'Hand the order, collect BHD ${amount.toStringAsFixed(3)}';
  }

  factory JobDetailOrder.fromJson(Map<String, dynamic> json) {
    final vendorRaw = json['vendor'] ?? json['vendorLocation'];
    final addressRaw = json['address'];
    final customerRaw = json['customer'];
    final itemsRaw = json['items'];

    return JobDetailOrder(
      id: json['id']?.toString() ?? '',
      orderNumber: json['orderNumber']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      fulfillmentType: json['fulfillmentType']?.toString() ?? '',
      paymentMethod: json['paymentMethod']?.toString() ?? '',
      paymentStatus: json['paymentStatus']?.toString() ?? '',
      totalAmount: _asDouble(json['totalAmount']),
      requiresCashCollection: json['requiresCashCollection'] == true,
      cashToCollectAmount: _asDouble(json['cashToCollectAmount']),
      tipAmount: _asDouble(json['tipAmount']),
      vendor: JobDetailVendor.fromJson(
        vendorRaw is Map
            ? Map<String, dynamic>.from(vendorRaw)
            : <String, dynamic>{},
      ),
      address: JobDetailAddress.fromJson(
        addressRaw is Map
            ? Map<String, dynamic>.from(addressRaw)
            : <String, dynamic>{},
      ),
      customer: JobDetailCustomer.fromJson(
        customerRaw is Map
            ? Map<String, dynamic>.from(customerRaw)
            : <String, dynamic>{},
      ),
      items: itemsRaw is List
          ? itemsRaw
              .whereType<Map>()
              .map(
                (item) =>
                    JobDetailItem.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList(growable: false)
          : const [],
      windowStartAt: _parseDate(json['windowStartAt']),
      windowEndAt: _parseDate(json['windowEndAt']),
      scheduledAt: _parseDate(json['scheduledAt']),
      kitchenNote: _nullableString(json['kitchenNote']),
    );
  }

  static String _dayLabel(DateTime value) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(value.year, value.month, value.day);
    if (day == today) return 'Today';
    if (day == today.add(const Duration(days: 1))) return 'Tomorrow';
    return '${value.day}/${value.month}';
  }

  static String _hourLabel(DateTime value) {
    final hour = value.hour;
    final minute = value.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final h12 = hour % 12 == 0 ? 12 : hour % 12;
    if (minute == 0) return '$h12 $period';
    return '$h12:${minute.toString().padLeft(2, '0')} $period';
  }

  static String? _nullableString(dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty || text.toLowerCase() == 'null') return null;
    return text;
  }

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}

class JobDetailVendor {
  const JobDetailVendor({
    required this.id,
    required this.name,
    required this.area,
    required this.city,
    this.latitude,
    this.longitude,
    this.phone,
    this.logoUrl,
  });

  final String id;
  final String name;
  final String area;
  final String city;
  final double? latitude;
  final double? longitude;
  final String? phone;
  final String? logoUrl;

  factory JobDetailVendor.fromJson(Map<String, dynamic> json) {
    return JobDetailVendor(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      area: json['area']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      latitude: _asNullableDouble(json['latitude']),
      longitude: _asNullableDouble(json['longitude']),
      phone: _nullableString(json['phone']),
      logoUrl: _nullableString(json['logoUrl']),
    );
  }

  static String? _nullableString(dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty || text.toLowerCase() == 'null') return null;
    return text;
  }

  static double? _asNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}

class JobDetailAddress {
  const JobDetailAddress({
    required this.id,
    required this.line1,
    required this.area,
    required this.city,
    this.line2,
    this.block,
    this.road,
    this.building,
    this.flat,
    this.latitude,
    this.longitude,
    this.additionalDirections,
  });

  final String id;
  final String line1;
  final String area;
  final String city;
  final String? line2;
  final String? block;
  final String? road;
  final String? building;
  final String? flat;
  final double? latitude;
  final double? longitude;
  final String? additionalDirections;

  /// Compact drop-off line used on the deliver screen.
  String get shortLabel {
    final parts = <String>[];
    if (area.trim().isNotEmpty) parts.add(area.trim());

    final buildingBits = <String>[];
    if (building != null && building!.trim().isNotEmpty) {
      buildingBits.add('Bldg ${building!.trim()}');
    }
    if (road != null && road!.trim().isNotEmpty) {
      buildingBits.add('Road ${road!.trim()}');
    }
    if (flat != null && flat!.trim().isNotEmpty) {
      buildingBits.add('Flat ${flat!.trim()}');
    }
    if (buildingBits.isNotEmpty) {
      parts.add(buildingBits.join(', '));
    } else if (line1.trim().isNotEmpty) {
      parts.add(line1.trim());
    }

    if (parts.isEmpty) return line1.trim().isNotEmpty ? line1.trim() : '—';
    return parts.join(' · ');
  }

  String get navigationAddress {
    final bits = <String>[
      if (line1.trim().isNotEmpty) line1.trim(),
      if (line2 != null && line2!.trim().isNotEmpty) line2!.trim(),
      if (area.trim().isNotEmpty) area.trim(),
      if (city.trim().isNotEmpty) city.trim(),
    ];
    return bits.isEmpty ? shortLabel : bits.join(', ');
  }

  factory JobDetailAddress.fromJson(Map<String, dynamic> json) {
    return JobDetailAddress(
      id: json['id']?.toString() ?? '',
      line1: json['line1']?.toString() ?? '',
      line2: _nullableString(json['line2']),
      block: _nullableString(json['block']),
      road: _nullableString(json['road']),
      building: _nullableString(json['building']),
      flat: _nullableString(json['flat']),
      area: json['area']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      latitude: _asNullableDouble(json['latitude']),
      longitude: _asNullableDouble(json['longitude']),
      additionalDirections: _nullableString(json['additionalDirections']),
    );
  }

  static String? _nullableString(dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty || text.toLowerCase() == 'null') return null;
    return text;
  }

  static double? _asNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}

class JobDetailCustomer {
  const JobDetailCustomer({
    required this.name,
    required this.phone,
    required this.countryCode,
    this.maskedPhone,
  });

  final String name;
  final String phone;
  final String countryCode;
  final String? maskedPhone;

  String get displayName {
    final trimmed = name.trim();
    return trimmed.isEmpty ? 'Customer' : trimmed;
  }

  String get displayPhone {
    final masked = maskedPhone?.trim();
    if (masked != null && masked.isNotEmpty) return masked;

    final code = countryCode.trim();
    final number = phone.trim();
    if (code.isNotEmpty && number.isNotEmpty) {
      return number.startsWith('+') ? number : '$code $number';
    }
    if (number.isNotEmpty) return number;
    return '—';
  }

  factory JobDetailCustomer.fromJson(Map<String, dynamic> json) {
    return JobDetailCustomer(
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      countryCode: json['countryCode']?.toString() ?? '',
      maskedPhone: _nullableString(json['maskedPhone']),
    );
  }

  static String? _nullableString(dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty || text.toLowerCase() == 'null') return null;
    return text;
  }
}

class JobDetailItem {
  const JobDetailItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    this.categoryName,
  });

  final String id;
  final String name;
  final int quantity;
  final double unitPrice;
  final String? categoryName;

  factory JobDetailItem.fromJson(Map<String, dynamic> json) {
    return JobDetailItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      quantity: _asInt(json['quantity']),
      unitPrice: _asDouble(json['unitPrice']),
      categoryName: _nullableString(json['categoryName']),
    );
  }

  static String? _nullableString(dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty || text.toLowerCase() == 'null') return null;
    return text;
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

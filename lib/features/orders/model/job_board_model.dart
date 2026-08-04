class JobsBoardCounts {
  const JobsBoardCounts({
    this.active = 0,
    this.completed = 0,
    this.newCount = 0,
    this.requireConfirmation = 0,
    this.onTrack = 0,
  });

  final int active;
  final int completed;
  final int newCount;
  final int requireConfirmation;
  final int onTrack;

  factory JobsBoardCounts.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const JobsBoardCounts();
    return JobsBoardCounts(
      active: _asInt(json['active']),
      completed: _asInt(json['completed']),
      newCount: _asInt(json['new']),
      requireConfirmation: _asInt(json['requireConfirmation']),
      onTrack: _asInt(json['onTrack']),
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class JobsBoardJob {
  const JobsBoardJob({
    required this.id,
    required this.status,
    required this.orderNumber,
    required this.vendorName,
    required this.pickupArea,
    required this.dropoffArea,
    required this.dropoffAddress,
    required this.paymentMethod,
    required this.driverEarnings,
    required this.totalAmount,
    required this.etaMin,
    required this.progress,
    this.statusLabel,
    this.statusMessage,
    this.routeLabel,
    this.meta,
    this.cancelReason,
    this.completedAt,
    this.scheduledWindow,
    this.respondWithin,
    this.expiresAt,
  });

  final String id;
  final String status;
  final String orderNumber;
  final String vendorName;
  final String pickupArea;
  final String dropoffArea;
  final String dropoffAddress;
  final String paymentMethod;
  final double driverEarnings;
  final double totalAmount;
  final int etaMin;
  final double progress;
  final String? statusLabel;
  final String? statusMessage;
  final String? routeLabel;
  final String? meta;
  final String? cancelReason;
  final DateTime? completedAt;
  final String? scheduledWindow;
  final String? respondWithin;
  final DateTime? expiresAt;

  bool get isDelivered {
    final s = status.toUpperCase();
    return s == 'DELIVERED' || s == 'COMPLETED';
  }

  bool get isCancelled {
    final s = status.toUpperCase();
    return s == 'CANCELLED' || s == 'CANCELED' || s.contains('CANCEL');
  }

  bool get isCash {
    final method = paymentMethod.toUpperCase();
    return method == 'CASH' || method == 'POD';
  }

  String get displayStatusLabel {
    final label = statusLabel?.trim();
    if (label != null && label.isNotEmpty) return label.toUpperCase();

    switch (status.toUpperCase()) {
      case 'DELIVERED':
      case 'COMPLETED':
        return 'DELIVERED';
      case 'CANCELLED':
      case 'CANCELED':
        return 'CANCELLED';
      case 'AT_CUSTOMER':
      case 'PICKED_UP':
      case 'ON_THE_WAY':
        return 'ON THE WAY';
      case 'AT_RESTAURANT':
      case 'AT_VENDOR':
        return 'AT VENDOR';
      case 'ACCEPTED':
      case 'ASSIGNED':
      case 'GOING_TO_VENDOR':
        return 'HEADING TO VENDOR';
      default:
        return status.replaceAll('_', ' ').toUpperCase();
    }
  }

  String get displayRoute {
    final route = routeLabel?.trim();
    if (route != null && route.isNotEmpty) return route;

    final dropoff = dropoffArea.trim().isNotEmpty
        ? dropoffArea.trim()
        : (dropoffAddress.trim().isNotEmpty
            ? dropoffAddress.trim()
            : 'Drop-off');
    final vendor = vendorName.trim().isNotEmpty ? vendorName.trim() : 'Vendor';
    return '$vendor → $dropoff';
  }

  String get completedRoute {
    final route = routeLabel?.trim();
    if (route != null && route.isNotEmpty) return route;

    final dropoff = dropoffAddress.trim().isNotEmpty
        ? dropoffAddress.trim()
        : (dropoffArea.trim().isNotEmpty ? dropoffArea.trim() : 'Drop-off');
    final vendor = vendorName.trim().isNotEmpty ? vendorName.trim() : 'Vendor';
    return '$vendor → $dropoff';
  }

  String get shortOrderNumber {
    var number = orderNumber.trim();
    if (number.isEmpty) return '';
    if (!number.startsWith('#')) number = '#$number';
    if (number.length <= 12) return number;
    return '${number.substring(0, 5)}...${number.substring(number.length - 2)}';
  }

  String get etaLabel {
    if (etaMin <= 0) return '';
    return '$etaMin min';
  }

  String get scheduledWindowLabel {
    final window = scheduledWindow?.trim();
    if (window != null && window.isNotEmpty) return window;
    return 'Window TBD';
  }

  String get respondWithinLabel {
    final label = respondWithin?.trim();
    if (label != null && label.isNotEmpty) return label;

    final expires = expiresAt;
    if (expires != null) {
      final remaining = expires.difference(DateTime.now());
      if (remaining.isNegative) return 'Response time expired';
      final totalMinutes = remaining.inMinutes;
      if (totalMinutes < 60) {
        return 'Respond within ${totalMinutes.clamp(1, 59)} min';
      }
      final hours = totalMinutes ~/ 60;
      final minutes = totalMinutes % 60;
      if (minutes == 0) return 'Respond within $hours hr';
      return 'Respond within $hours hr $minutes min';
    }

    return 'Respond soon';
  }

  String get displayOrderId {
    final short = shortOrderNumber;
    if (short.isNotEmpty) return short;
    if (id.isNotEmpty) return id.startsWith('#') ? id : '#$id';
    return '#—';
  }

  String get activeSubtitle {
    final parts = <String>[];
    final order = shortOrderNumber;
    if (order.isNotEmpty) parts.add(order);

    if (isCash && totalAmount > 0) {
      parts.add('cash BHD ${_money(totalAmount)}');
    } else if (paymentMethod.trim().isNotEmpty) {
      parts.add(paymentMethod.trim().toLowerCase());
    }
    return parts.join(' · ');
  }

  String get arrivingLabel {
    final message = statusMessage?.trim();
    if (message != null && message.isNotEmpty) return message;
    if (etaMin > 0) return 'Arriving in $etaMin min';
    return 'In progress';
  }

  String? get earningsLabel {
    if (driverEarnings <= 0) return null;
    final trimmed = driverEarnings == driverEarnings.roundToDouble()
        ? driverEarnings.toStringAsFixed(1)
        : _money(driverEarnings);
    return 'BHD $trimmed';
  }

  String get completedMeta {
    final provided = meta?.trim();
    if (provided != null && provided.isNotEmpty) return provided;

    final time = _formatTime(completedAt);
    if (isCancelled) {
      final reason = cancelReason?.trim();
      if (time.isNotEmpty && reason != null && reason.isNotEmpty) {
        return '$time · $reason';
      }
      if (reason != null && reason.isNotEmpty) return reason;
      if (time.isNotEmpty) return '$time · cancelled';
      return 'Cancelled';
    }

    if (time.isNotEmpty && driverEarnings > 0) {
      return '$time · BHD ${_money(driverEarnings)}';
    }
    if (time.isNotEmpty) return time;
    if (driverEarnings > 0) return 'BHD ${_money(driverEarnings)}';
    return '';
  }

  double get progressValue {
    if (progress <= 0) return 0.15;
    if (progress > 1) return (progress / 100).clamp(0.0, 1.0);
    return progress.clamp(0.0, 1.0);
  }

  factory JobsBoardJob.fromJson(Map<String, dynamic> json) {
    final vendor = _asMap(json['vendor']);
    final pickup = _asMap(json['pickup'] ?? json['pickupLocation']);
    final dropoff = _asMap(json['dropoff'] ?? json['dropoffLocation']);
    final scheduled = _asMap(json['scheduled'] ?? json['schedule']);

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
      json['customerArea'],
    ]);

    final dropoffAddress = _firstNonEmpty([
      json['dropoffAddress'],
      dropoff?['address'],
      dropoff?['fullAddress'],
      dropoffArea,
    ]);

    return JobsBoardJob(
      id: json['id']?.toString() ?? json['jobId']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      orderNumber: json['orderNumber']?.toString() ??
          json['orderId']?.toString() ??
          '',
      vendorName: vendorName.isEmpty ? 'Vendor' : vendorName,
      pickupArea: pickupArea,
      dropoffArea: dropoffArea,
      dropoffAddress: dropoffAddress,
      paymentMethod: json['paymentMethod']?.toString() ??
          json['paymentType']?.toString() ??
          '',
      driverEarnings: _asDouble(
        json['driverEarnings'] ?? json['earnings'] ?? json['payout'],
      ),
      totalAmount: _asDouble(
        json['totalAmount'] ?? json['cashToCollect'] ?? json['orderTotal'],
      ),
      etaMin: _asInt(
        json['etaMin'] ??
            json['durationMin'] ??
            json['estimatedDurationMin'] ??
            json['etaMinutes'],
      ),
      progress: _asDouble(
        json['progress'] ??
            json['progressPercent'] ??
            json['completionPercent'] ??
            json['progressRatio'],
      ),
      statusLabel: _nullableString(json['statusLabel'] ?? json['badge']),
      statusMessage: _nullableString(
        json['statusMessage'] ??
            json['statusLine'] ??
            json['subtitle'] ??
            json['message'],
      ),
      routeLabel: _nullableString(
        json['routeLabel'] ?? json['route'] ?? json['title'],
      ),
      meta: _nullableString(json['meta'] ?? json['footer'] ?? json['detail']),
      cancelReason: _nullableString(
        json['cancelReason'] ??
            json['cancellationReason'] ??
            json['cancelledReason'] ??
            json['reason'],
      ),
      completedAt: _parseDate(
        json['completedAt'] ??
            json['deliveredAt'] ??
            json['cancelledAt'] ??
            json['updatedAt'],
      ),
      scheduledWindow: _nullableString(
        json['scheduledWindow'] ??
            json['window'] ??
            json['windowLabel'] ??
            json['deliveryWindow'] ??
            scheduled?['window'] ??
            scheduled?['windowLabel'] ??
            scheduled?['label'],
      ),
      respondWithin: _nullableString(
        json['respondWithin'] ??
            json['respondIn'] ??
            json['respondByLabel'] ??
            json['responseWindow'] ??
            json['expiresInLabel'] ??
            scheduled?['respondWithin'] ??
            scheduled?['respondIn'],
      ),
      expiresAt: _parseDate(
        json['expiresAt'] ??
            json['respondBy'] ??
            json['offerExpiresAt'] ??
            scheduled?['expiresAt'] ??
            scheduled?['respondBy'],
      ),
    );
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

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  static String _money(double value) => value.toStringAsFixed(3);

  static String _formatTime(DateTime? value) {
    if (value == null) return '';
    final local = value.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class JobsBoardData {
  const JobsBoardData({
    required this.type,
    required this.section,
    required this.counts,
    required this.jobs,
  });

  final String type;
  final String section;
  final JobsBoardCounts counts;
  final List<JobsBoardJob> jobs;

  factory JobsBoardData.fromJson(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is! Map) {
      throw const FormatException('Invalid jobs board response');
    }
    final map = Map<String, dynamic>.from(data);
    final countsRaw = map['counts'];

    return JobsBoardData(
      type: map['type']?.toString() ?? '',
      section: map['section']?.toString() ?? '',
      counts: JobsBoardCounts.fromJson(
        countsRaw is Map ? Map<String, dynamic>.from(countsRaw) : null,
      ),
      jobs: _parseJobs(map['jobs']),
    );
  }

  static List<JobsBoardJob> _parseJobs(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => JobsBoardJob.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }
}

class JobsHistoryData {
  const JobsHistoryData({
    required this.type,
    required this.count,
    required this.jobs,
  });

  final String type;
  final int count;
  final List<JobsBoardJob> jobs;

  factory JobsHistoryData.fromJson(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is! Map) {
      throw const FormatException('Invalid jobs history response');
    }
    final map = Map<String, dynamic>.from(data);

    return JobsHistoryData(
      type: map['type']?.toString() ?? '',
      count: _asInt(map['count']),
      jobs: _parseJobs(map['jobs']),
    );
  }

  static List<JobsBoardJob> _parseJobs(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => JobsBoardJob.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

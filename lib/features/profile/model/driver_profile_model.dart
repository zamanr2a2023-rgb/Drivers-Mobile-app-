class DriverProfileModel {
  const DriverProfileModel({
    required this.id,
    required this.displayCode,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.language,
    required this.tier,
    required this.country,
    required this.city,
    required this.zone,
    required this.status,
    required this.accountStatus,
    required this.isAutoAcceptEnabled,
    required this.isIdVerified,
    required this.averageRating,
    required this.rpiScore,
    required this.lifetimeDeliveries,
    this.avatarUrl,
    this.phone,
    this.gender,
  });

  final String id;
  final String displayCode;
  final String firstName;
  final String lastName;
  final String email;
  final String? avatarUrl;
  final String language;
  final String? gender;
  final String tier;
  final String country;
  final String city;
  final String zone;
  final String status;
  final String accountStatus;
  final bool isAutoAcceptEnabled;
  final bool isIdVerified;
  final double averageRating;
  final double rpiScore;
  final int lifetimeDeliveries;
  final String? phone;

  String get displayName {
    final name = '$firstName $lastName'.trim();
    return name.isEmpty ? 'Driver' : name;
  }

  String get initials {
    final first = firstName.trim();
    final last = lastName.trim();
    final a = first.isNotEmpty ? first[0].toUpperCase() : '';
    final b = last.isNotEmpty ? last[0].toUpperCase() : '';
    final value = '$a$b';
    return value.isNotEmpty ? value : 'DR';
  }

  /// Dial code derived from [country] when available.
  String get countryCode {
    switch (country.toUpperCase()) {
      case 'BH':
        return '+973';
      case 'BD':
        return '+880';
      case 'SA':
        return '+966';
      case 'AE':
        return '+971';
      case 'KW':
        return '+965';
      case 'QA':
        return '+974';
      case 'OM':
        return '+968';
      default:
        return '+973';
    }
  }

  String get formattedPhone {
    final raw = phone?.trim() ?? '';
    if (raw.isEmpty) return '';
    if (raw.startsWith('+')) return raw;
    return '$countryCode $raw';
  }

  factory DriverProfileModel.fromJson(Map<String, dynamic> json) {
    final userRaw = json['user'];
    final user = userRaw is Map ? Map<String, dynamic>.from(userRaw) : null;

    return DriverProfileModel(
      id: json['id']?.toString() ?? '',
      displayCode: json['displayCode']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      email: json['email']?.toString() ?? user?['email']?.toString() ?? '',
      avatarUrl: json['avatarUrl']?.toString(),
      language: json['language']?.toString() ?? 'en',
      gender: json['gender']?.toString(),
      tier: json['tier']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      zone: json['zone']?.toString() ?? '',
      status: json['status']?.toString() ?? 'OFFLINE',
      accountStatus: json['accountStatus']?.toString() ?? '',
      isAutoAcceptEnabled: json['isAutoAcceptEnabled'] == true,
      isIdVerified: json['isIdVerified'] == true,
      averageRating: _asDouble(json['averageRating']),
      rpiScore: _asDouble(json['rpiScore']),
      lifetimeDeliveries: _asInt(json['lifetimeDeliveries']),
      phone: user?['phone']?.toString(),
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

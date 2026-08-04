class PersonalAccountModel {
  const PersonalAccountModel({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.countryCode,
    required this.language,
    required this.isAutoAcceptEnabled,
    this.dateOfBirth,
    this.gender,
    this.avatarUrl,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String countryCode;
  final String? dateOfBirth;
  final String? gender;
  final String? avatarUrl;
  final String language;
  final bool isAutoAcceptEnabled;

  String get fullName {
    final name = '$firstName $lastName'.trim();
    return name;
  }

  String get formattedPhone {
    final raw = phone.trim();
    if (raw.isEmpty) return '';
    if (raw.startsWith('+')) return raw;
    final code = countryCode.trim();
    if (code.isEmpty) return raw;
    return '$code $raw';
  }

  factory PersonalAccountModel.fromJson(Map<String, dynamic> json) {
    return PersonalAccountModel(
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      countryCode: json['countryCode']?.toString() ?? '',
      dateOfBirth: json['dateOfBirth']?.toString(),
      gender: json['gender']?.toString(),
      avatarUrl: json['avatarUrl']?.toString(),
      language: json['language']?.toString() ?? 'en',
      isAutoAcceptEnabled: json['isAutoAcceptEnabled'] == true,
    );
  }
}

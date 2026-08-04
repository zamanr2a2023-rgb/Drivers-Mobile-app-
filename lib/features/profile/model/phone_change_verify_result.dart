class PhoneChangeVerifyResult {
  const PhoneChangeVerifyResult({
    required this.message,
    required this.phone,
    required this.countryCode,
    required this.accessToken,
    required this.refreshToken,
  });

  final String message;
  final String phone;
  final String countryCode;
  final String accessToken;
  final String refreshToken;

  factory PhoneChangeVerifyResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is! Map) {
      throw const FormatException('Invalid phone verify response');
    }

    final map = Map<String, dynamic>.from(data);
    final accessToken = map['accessToken']?.toString() ?? '';
    final refreshToken = map['refreshToken']?.toString() ?? '';
    if (accessToken.isEmpty || refreshToken.isEmpty) {
      throw const FormatException('Invalid phone verify response');
    }

    return PhoneChangeVerifyResult(
      message: map['message']?.toString() ?? 'Phone number updated',
      phone: map['phone']?.toString() ?? '',
      countryCode: map['countryCode']?.toString() ?? '',
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }
}

/// Response from `POST /drivers/jobs/:jobId/contact-attempts`
/// (also nested under job detail `contactAttempts`).
class ContactAttemptsResult {
  const ContactAttemptsResult({
    required this.attempts,
    required this.requiredForUnableToDeliver,
    required this.canMarkUnableToDeliver,
    this.message,
  });

  final List<ContactAttempt> attempts;
  final int requiredForUnableToDeliver;
  final bool canMarkUnableToDeliver;
  final String? message;

  factory ContactAttemptsResult.fromJson(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is! Map) {
      throw const FormatException('Invalid contact attempts response');
    }
    return ContactAttemptsResult.fromData(Map<String, dynamic>.from(data));
  }

  factory ContactAttemptsResult.fromData(Map<String, dynamic> json) {
    final attemptsRaw = json['attempts'];
    return ContactAttemptsResult(
      message: _nullableString(json['message']),
      attempts: attemptsRaw is List
          ? attemptsRaw
              .whereType<Map>()
              .map(
                (item) =>
                    ContactAttempt.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList(growable: false)
          : const [],
      requiredForUnableToDeliver: _asInt(
        json['requiredForUnableToDeliver'],
        fallback: 2,
      ),
      canMarkUnableToDeliver: json['canMarkUnableToDeliver'] == true,
    );
  }

  static String? _nullableString(dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty || text.toLowerCase() == 'null') return null;
    return text;
  }

  static int _asInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}

class ContactAttempt {
  const ContactAttempt({
    required this.type,
    this.at,
  });

  final String type;
  final DateTime? at;

  bool get isCall => type.toUpperCase() == 'CALL';

  String get titleLabel {
    final indexType = isCall ? 'Call' : type.replaceAll('_', ' ');
    return indexType;
  }

  String get loggedLabel {
    if (at == null) return 'Logged';
    final local = at!.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return 'Logged $hour:$minute';
  }

  factory ContactAttempt.fromJson(Map<String, dynamic> json) {
    return ContactAttempt(
      type: json['type']?.toString() ?? 'CALL',
      at: _parseDate(json['at']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}

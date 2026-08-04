/// Response from `POST /drivers/jobs/:jobId/report-wait`.
class JobReportWaitResult {
  const JobReportWaitResult({
    required this.message,
    required this.alreadyReported,
    this.wait,
  });

  final String message;
  final bool alreadyReported;
  final JobWaitInfo? wait;

  factory JobReportWaitResult.fromJson(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is! Map) {
      throw const FormatException('Invalid report-wait response');
    }
    final map = Map<String, dynamic>.from(data);
    final waitRaw = map['wait'];

    return JobReportWaitResult(
      message: map['message']?.toString() ??
          'Wait reported to dispatch. Your wait time is excluded from RPI.',
      alreadyReported: map['alreadyReported'] == true,
      wait: waitRaw is Map
          ? JobWaitInfo.fromJson(Map<String, dynamic>.from(waitRaw))
          : null,
    );
  }
}

class JobWaitInfo {
  const JobWaitInfo({
    required this.active,
    required this.waitingSec,
    required this.waitingLabel,
    required this.autoFlagAtSec,
    required this.autoFlagged,
    required this.reported,
    required this.rpiExcluded,
    this.waitingSince,
    this.reportedAt,
    this.message,
  });

  final bool active;
  final int waitingSec;
  final String waitingLabel;
  final int autoFlagAtSec;
  final bool autoFlagged;
  final bool reported;
  final bool rpiExcluded;
  final DateTime? waitingSince;
  final DateTime? reportedAt;
  final String? message;

  factory JobWaitInfo.fromJson(Map<String, dynamic> json) {
    return JobWaitInfo(
      active: json['active'] == true,
      waitingSec: _asInt(json['waitingSec']),
      waitingLabel: json['waitingLabel']?.toString() ?? '00:00',
      autoFlagAtSec: _asInt(json['autoFlagAtSec']),
      autoFlagged: json['autoFlagged'] == true,
      reported: json['reported'] == true,
      rpiExcluded: json['rpiExcluded'] == true,
      waitingSince: _parseDate(json['waitingSince']),
      reportedAt: _parseDate(json['reportedAt']),
      message: _nullableString(json['message']),
    );
  }

  static String? _nullableString(dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty || text.toLowerCase() == 'null') return null;
    return text;
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
}

/// Response from `POST /drivers/jobs/:jobId/report`.
class JobReportResult {
  const JobReportResult({
    required this.message,
    this.incident,
  });

  final String message;
  final JobReportIncident? incident;

  factory JobReportResult.fromJson(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is! Map) {
      throw const FormatException('Invalid job report response');
    }
    final map = Map<String, dynamic>.from(data);
    final incidentRaw = map['incident'];

    return JobReportResult(
      message: map['message']?.toString() ?? 'Issue reported to Yjeek Ops',
      incident: incidentRaw is Map
          ? JobReportIncident.fromJson(Map<String, dynamic>.from(incidentRaw))
          : null,
    );
  }
}

class JobReportIncident {
  const JobReportIncident({
    required this.id,
    required this.type,
    required this.title,
    required this.reason,
    required this.priority,
    required this.status,
    this.createdAt,
  });

  final String id;
  final String type;
  final String title;
  final String reason;
  final String priority;
  final String status;
  final DateTime? createdAt;

  factory JobReportIncident.fromJson(Map<String, dynamic> json) {
    return JobReportIncident(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      priority: json['priority']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      createdAt: _parseDate(json['createdAt']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}

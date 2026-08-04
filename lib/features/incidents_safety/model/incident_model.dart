class IncidentModel {
  const IncidentModel({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String description;
  final String status;
  final DateTime createdAt;
}

/// Response from `POST /drivers/jobs/:jobId/sos`.
class JobSosResult {
  const JobSosResult({
    required this.message,
    this.incident,
  });

  final String message;
  final JobSosIncident? incident;

  factory JobSosResult.fromJson(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is! Map) {
      throw const FormatException('Invalid SOS response');
    }
    final map = Map<String, dynamic>.from(data);
    final incidentRaw = map['incident'];

    return JobSosResult(
      message: map['message']?.toString() ?? 'SOS sent to Yjeek Ops',
      incident: incidentRaw is Map
          ? JobSosIncident.fromJson(Map<String, dynamic>.from(incidentRaw))
          : null,
    );
  }
}

class JobSosIncident {
  const JobSosIncident({
    required this.id,
    required this.type,
    required this.priority,
    required this.status,
    this.createdAt,
  });

  final String id;
  final String type;
  final String priority;
  final String status;
  final DateTime? createdAt;

  factory JobSosIncident.fromJson(Map<String, dynamic> json) {
    return JobSosIncident(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
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

import 'package:yjeek_driver/core/constants/api_endpoints.dart';
import 'package:yjeek_driver/features/incidents_safety/model/incident_model.dart';
import 'package:yjeek_driver/services/api_service.dart';

class IncidentService {
  IncidentService({ApiService? apiService})
      : _api = apiService ?? ApiService.instance;

  final ApiService _api;

  Future<List<IncidentModel>> getIncidents() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return [
      IncidentModel(
        id: 'INC-001',
        title: 'Late delivery report',
        description: 'Customer reported late delivery for order #ORD-998',
        status: 'Resolved',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ];
  }

  Future<bool> submitReport({
    required String issueType,
    required String description,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }

  Future<bool> submitItemIssue({
    required List<String> issues,
    required String notes,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }

  /// Sends an SOS for the active job to Yjeek Ops.
  Future<JobSosResult> sendJobSos({
    required String jobId,
    required String note,
    required double latitude,
    required double longitude,
  }) async {
    final id = jobId.trim();
    if (id.isEmpty) {
      throw ApiException('Job id is required');
    }

    final response = await _api.post(
      ApiEndpoints.jobSos(id),
      body: {
        'note': note.trim().isEmpty ? 'Driver emergency SOS' : note.trim(),
        'latitude': latitude,
        'longitude': longitude,
      },
    );

    if (response['success'] != true) {
      throw ApiException(_failureMessage(response, 'Failed to send SOS'));
    }

    try {
      return JobSosResult.fromJson(response);
    } on FormatException {
      throw ApiException('Invalid response from server');
    }
  }

  /// Sends a general SOS when there is no active job context.
  Future<JobSosResult> sendDriverSos({required String note}) async {
    final response = await _api.post(
      ApiEndpoints.driverSos,
      body: {
        'note': note.trim().isEmpty
            ? 'Emergency — no active job context'
            : note.trim(),
      },
    );

    if (response['success'] != true) {
      throw ApiException(_failureMessage(response, 'Failed to send SOS'));
    }

    try {
      return JobSosResult.fromJson(response);
    } on FormatException {
      throw ApiException('Invalid response from server');
    }
  }

  String _failureMessage(Map<String, dynamic> response, String fallback) {
    final message = response['message']?.toString();
    if (message != null && message.trim().isNotEmpty) return message.trim();

    final error = response['error'];
    if (error is Map) {
      final nested = error['message']?.toString();
      if (nested != null && nested.trim().isNotEmpty) return nested.trim();
    }

    return fallback;
  }
}

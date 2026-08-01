import 'package:flutter/foundation.dart';
import 'package:yjeek_driver/features/incidents_safety/model/incident_model.dart';
import 'package:yjeek_driver/features/incidents_safety/service/incident_service.dart';
import 'package:yjeek_driver/services/api_service.dart';

class IncidentProvider extends ChangeNotifier {
  IncidentProvider({IncidentService? incidentService})
      : _service = incidentService ?? IncidentService();

  final IncidentService _service;

  bool _isLoading = false;
  bool _isSendingSos = false;
  List<IncidentModel> _incidents = [];
  JobSosResult? _lastSosResult;
  String? _sosError;

  bool get isLoading => _isLoading;
  bool get isSendingSos => _isSendingSos;
  List<IncidentModel> get incidents => _incidents;
  JobSosResult? get lastSosResult => _lastSosResult;
  String? get sosError => _sosError;

  Future<void> loadIncidents() async {
    _isLoading = true;
    notifyListeners();
    _incidents = await _service.getIncidents();
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> submitReport(String issueType, String description) async {
    _isLoading = true;
    notifyListeners();
    final result = await _service.submitReport(
      issueType: issueType,
      description: description,
    );
    _isLoading = false;
    notifyListeners();
    return result;
  }

  Future<bool> submitItemIssue(List<String> issues, String notes) async {
    _isLoading = true;
    notifyListeners();
    final result = await _service.submitItemIssue(issues: issues, notes: notes);
    _isLoading = false;
    notifyListeners();
    return result;
  }

  Future<JobSosResult?> sendJobSos({
    required String jobId,
    required String note,
    required double latitude,
    required double longitude,
  }) async {
    _isSendingSos = true;
    _sosError = null;
    _lastSosResult = null;
    notifyListeners();

    try {
      final result = await _service.sendJobSos(
        jobId: jobId,
        note: note,
        latitude: latitude,
        longitude: longitude,
      );
      _lastSosResult = result;
      return result;
    } on ApiException catch (e) {
      _sosError = e.message;
      return null;
    } catch (_) {
      _sosError = 'Failed to send SOS';
      return null;
    } finally {
      _isSendingSos = false;
      notifyListeners();
    }
  }

  Future<JobSosResult?> sendDriverSos({required String note}) async {
    _isSendingSos = true;
    _sosError = null;
    _lastSosResult = null;
    notifyListeners();

    try {
      final result = await _service.sendDriverSos(note: note);
      _lastSosResult = result;
      return result;
    } on ApiException catch (e) {
      _sosError = e.message;
      return null;
    } catch (_) {
      _sosError = 'Failed to send SOS';
      return null;
    } finally {
      _isSendingSos = false;
      notifyListeners();
    }
  }

  void clearSosState() {
    _lastSosResult = null;
    _sosError = null;
    _isSendingSos = false;
    notifyListeners();
  }
}

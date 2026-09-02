import 'package:yjeek_driver/core/constants/api_endpoints.dart';
import 'package:yjeek_driver/features/dashboard/model/home_model.dart';
import 'package:yjeek_driver/features/dashboard/model/ui_banner_model.dart';
import 'package:yjeek_driver/services/api_service.dart';

class DashboardService {
  DashboardService({ApiService? apiService})
      : _api = apiService ?? ApiService.instance;

  final ApiService _api;

  Future<DriverHomeModel> getHome() async {
    final response = await _api.get(ApiEndpoints.home);
    return _parseHomeResponse(
      response,
      failureMessage: 'Failed to load home',
    );
  }

  Future<DriverHomeModel> goOnline({
    required double latitude,
    required double longitude,
  }) async {
    final response = await _api.post(
      ApiEndpoints.goOnline,
      body: {
        'latitude': latitude,
        'longitude': longitude,
      },
    );
    return _parseHomeResponse(
      response,
      failureMessage: 'Failed to go online',
    );
  }

  Future<DriverHomeModel> goOffline() async {
    final response = await _api.post(ApiEndpoints.goOffline);
    return _parseHomeResponse(
      response,
      failureMessage: 'Failed to go offline',
    );
  }

  Future<void> updateLocation({
    required double latitude,
    required double longitude,
  }) async {
    final response = await _api.patch(
      ApiEndpoints.driverLocation,
      body: {
        'latitude': latitude,
        'longitude': longitude,
      },
    );

    if (response['success'] != true) {
      throw ApiException(
        response['message']?.toString().trim().isNotEmpty == true
            ? response['message'].toString().trim()
            : 'Failed to update location',
      );
    }
  }

  Future<HomeDriverModel> updateDriverStatus(String status) async {
    final response = await _api.patch(
      ApiEndpoints.driverStatus,
      body: {'status': status},
    );

    if (response['success'] != true) {
      final message = response['message']?.toString();
      throw ApiException(
        (message != null && message.trim().isNotEmpty)
            ? message.trim()
            : 'Failed to update driver status',
      );
    }

    final data = response['data'];
    if (data is! Map) {
      throw ApiException('Invalid response from server');
    }

    try {
      return HomeDriverModel.fromJson(Map<String, dynamic>.from(data));
    } on FormatException {
      throw ApiException('Invalid response from server');
    }
  }

  Future<HomeUiBannersModel> getHomeBanners() async {
    final response = await _api.get(ApiEndpoints.publicBannersHome);
    if (response['success'] != true) {
      final message = response['message']?.toString().trim();
      throw ApiException(
        (message != null && message.isNotEmpty)
            ? message
            : 'Failed to load banners',
      );
    }

    try {
      return HomeUiBannersModel.fromJson(response);
    } on FormatException {
      throw ApiException('Invalid response from server');
    }
  }

  Future<bool> setAutoAccept({required bool enabled}) async {
    final response = await _api.patch(
      ApiEndpoints.autoAccept,
      body: {'enabled': enabled},
    );

    if (response['success'] != true) {
      final message = response['message']?.toString();
      throw ApiException(
        (message != null && message.trim().isNotEmpty)
            ? message.trim()
            : 'Failed to update auto-accept',
      );
    }

    final data = response['data'];
    if (data is Map && data.containsKey('isAutoAcceptEnabled')) {
      return data['isAutoAcceptEnabled'] == true;
    }

    return enabled;
  }

  DriverHomeModel _parseHomeResponse(
    Map<String, dynamic> response, {
    required String failureMessage,
  }) {
    if (response['success'] != true) {
      final message = response['message']?.toString();
      throw ApiException(
        (message != null && message.trim().isNotEmpty)
            ? message.trim()
            : failureMessage,
      );
    }

    try {
      return DriverHomeModel.fromJson(response);
    } on FormatException {
      throw ApiException('Invalid response from server');
    }
  }
}

import 'package:yjeek_driver/core/constants/api_endpoints.dart';
import 'package:yjeek_driver/features/notifications/model/notification_model.dart';
import 'package:yjeek_driver/services/api_service.dart';

class NotificationService {
  NotificationService({ApiService? apiService})
      : _api = apiService ?? ApiService.instance;

  final ApiService _api;

  Future<NotificationsListData> getNotifications() async {
    final response = await _api.get(ApiEndpoints.notifications);

    if (response['success'] != true) {
      final message = response['message']?.toString();
      throw ApiException(
        (message != null && message.trim().isNotEmpty)
            ? message.trim()
            : 'Failed to load notifications',
      );
    }

    try {
      return NotificationsListData.fromJson(response);
    } on FormatException {
      throw ApiException('Invalid response from server');
    }
  }

  Future<void> markAllAsRead() async {
    final response = await _api.patch(ApiEndpoints.notificationsReadAll);

    if (response['success'] != true) {
      final message = response['message']?.toString();
      throw ApiException(
        (message != null && message.trim().isNotEmpty)
            ? message.trim()
            : 'Failed to mark notifications as read',
      );
    }
  }

  Future<void> markAsRead(String notificationId) async {
    final id = notificationId.trim();
    if (id.isEmpty) {
      throw ApiException('Notification not found');
    }

    final response = await _api.patch(ApiEndpoints.notificationRead(id));

    if (response['success'] != true) {
      throw ApiException(
        _failureMessage(response, 'Failed to mark notification as read'),
      );
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

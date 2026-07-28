import 'package:flutter/foundation.dart';
import 'package:yjeek_driver/features/notifications/model/notification_model.dart';
import 'package:yjeek_driver/features/notifications/service/notification_service.dart';
import 'package:yjeek_driver/services/api_service.dart';

class NotificationProvider extends ChangeNotifier {
  NotificationProvider({NotificationService? service})
      : _service = service ?? NotificationService();

  final NotificationService _service;

  bool _isLoading = false;
  bool _isMarkingAllRead = false;
  String? _error;
  List<NotificationModel> _today = const [];
  List<NotificationModel> _earlier = const [];
  int _unreadCount = 0;

  bool get isLoading => _isLoading;
  bool get isMarkingAllRead => _isMarkingAllRead;
  String? get error => _error;
  List<NotificationModel> get today => _today;
  List<NotificationModel> get earlier => _earlier;
  int get unreadCount => _unreadCount;
  bool get hasUnread => _unreadCount > 0;

  List<NotificationModel> get notifications => [..._today, ..._earlier];

  Future<void> loadNotifications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _service.getNotifications();
      _today = data.today;
      _earlier = data.earlier;
      _unreadCount = data.unreadCount;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Failed to load notifications';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void markAsRead(String id) {
    _applyLocalRead(id);
    notifyListeners();
  }

  Future<bool> markOneAsRead(String id) async {
    final trimmed = id.trim();
    if (trimmed.isEmpty) return false;

    final alreadyRead = notifications.any((n) => n.id == trimmed && n.isRead);
    if (alreadyRead) return true;

    try {
      await _service.markAsRead(trimmed);
      _applyLocalRead(trimmed);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'Failed to mark notification as read';
      notifyListeners();
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    if (_isMarkingAllRead || !hasUnread) return true;

    _isMarkingAllRead = true;
    notifyListeners();

    try {
      await _service.markAllAsRead();
      _today =
          _today.map((n) => n.copyWith(isRead: true)).toList(growable: false);
      _earlier =
          _earlier.map((n) => n.copyWith(isRead: true)).toList(growable: false);
      _unreadCount = 0;
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } catch (_) {
      _error = 'Failed to mark notifications as read';
      return false;
    } finally {
      _isMarkingAllRead = false;
      notifyListeners();
    }
  }

  void _applyLocalRead(String id) {
    _today = _markListRead(_today, id);
    _earlier = _markListRead(_earlier, id);
    _unreadCount = notifications.where((n) => !n.isRead).length;
  }

  List<NotificationModel> _markListRead(
    List<NotificationModel> source,
    String id,
  ) {
    return source
        .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
        .toList(growable: false);
  }
}

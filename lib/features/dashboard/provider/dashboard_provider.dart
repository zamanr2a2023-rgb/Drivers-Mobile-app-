import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:yjeek_driver/features/dashboard/model/home_model.dart';
import 'package:yjeek_driver/features/dashboard/service/dashboard_service.dart';
import 'package:yjeek_driver/services/api_service.dart';
import 'package:yjeek_driver/services/location_service.dart';

class DashboardProvider extends ChangeNotifier {
  DashboardProvider({
    DashboardService? dashboardService,
    LocationService? locationService,
  })  : _dashboardService = dashboardService ?? DashboardService(),
        _locationService = locationService ?? LocationService();

  final DashboardService _dashboardService;
  final LocationService _locationService;

  bool _isOnline = false;
  bool _isLoading = false;
  bool _isUpdatingAutoAccept = false;
  String _currentLocation = 'Fetching location...';
  DriverHomeModel? _home;
  String? _error;
  Timer? _locationHeartbeat;

  bool get isOnline => _isOnline;
  bool get isLoading => _isLoading;
  bool get isUpdatingAutoAccept => _isUpdatingAutoAccept;
  String get currentLocation => _currentLocation;
  DriverHomeModel? get home => _home;
  String? get error => _error;

  String get driverName => _home?.driver.displayName ?? 'Driver';

  String get statusLabel => _isOnline ? "You're online" : 'Offline';

  int get tripsToday => _home?.today.ordersCount ?? 0;

  double get todayEarnings => _home?.today.totalEarnings ?? 0;

  String get todayEarningsLabel => _formatBhd(todayEarnings);

  String get onlineDurationLabel =>
      _home?.today.onlineDurationLabel.isNotEmpty == true
          ? _home!.today.onlineDurationLabel
          : '0m';

  int get scheduledOrdersCount => _home?.scheduledOrdersCount ?? 0;

  String get scheduledOrdersLabel =>
      '$scheduledOrdersCount scheduled orders today';

  int get unreadNotificationsCount => _home?.unreadNotificationsCount ?? 0;

  bool get hasUnreadNotifications => unreadNotificationsCount > 0;

  double get walletBalance => _home?.wallet.balance ?? 0;

  String get walletBalanceLabel => _formatBhd(walletBalance);

  bool get isAutoAcceptEnabled => _home?.driver.isAutoAcceptEnabled ?? false;

  String get autoAcceptTitle =>
      isAutoAcceptEnabled ? 'Auto-Accept is on' : 'Auto-Accept is off';

  String get autoAcceptSubtitle => isAutoAcceptEnabled
      ? 'Orders will be accepted automatically'
      : 'Turn it on to get orders automatically';

  // Kept for existing callers that used mock fields.
  int get completedOrders => tripsToday;
  double get acceptanceRate => 0;

  Future<void> loadDashboard() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final homeFuture = _dashboardService.getHome();
      final locationFuture = _locationService.getCurrentLocation();
      _home = await homeFuture;
      _currentLocation = await locationFuture;
      _isOnline = _home!.driver.isOnlineStatus;
      _syncLocationHeartbeat();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Failed to load home';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _syncLocationHeartbeat() {
    if (!_isOnline) {
      _locationHeartbeat?.cancel();
      _locationHeartbeat = null;
      return;
    }
    if (_locationHeartbeat != null) return;
    _locationHeartbeat = Timer.periodic(
      const Duration(seconds: 45),
      (_) => _pushCurrentLocation(),
    );
    _pushCurrentLocation();
  }

  Future<void> _pushCurrentLocation() async {
    if (!_isOnline) return;
    try {
      final location = await _locationService.getCurrentMapLocation();
      if (location == null) return;
      await _dashboardService.updateLocation(
        latitude: location.latitude,
        longitude: location.longitude,
      );
      _currentLocation =
          '${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)}';
    } catch (_) {
      // Keep online session alive even if a single location ping fails.
    }
  }

  Future<bool> toggleOnlineStatus() async {
    if (_isOnline) {
      return goOffline();
    }

    return goOnline();
  }

  Future<bool> goOnline() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      var location = await _locationService.getCurrentMapLocation();
      if (location == null) {
        await _locationService.requestLocationPermission();
        location = await _locationService.getCurrentMapLocation();
      }
      if (location == null) {
        throw ApiException('Location is required to go online');
      }

      final home = await _dashboardService.goOnline(
        latitude: location.latitude,
        longitude: location.longitude,
      );
      _home = home;
      _isOnline = home.driver.isOnlineStatus;
      _syncLocationHeartbeat();
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'Failed to go online';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> goOffline() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final home = await _dashboardService.goOffline();
      _home = home;
      _isOnline = home.driver.isOnlineStatus;
      _syncLocationHeartbeat();
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'Failed to go offline';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> setAutoAcceptEnabled(bool enabled) async {
    if (_isUpdatingAutoAccept) return false;

    _isUpdatingAutoAccept = true;
    _error = null;
    notifyListeners();

    try {
      final isEnabled =
          await _dashboardService.setAutoAccept(enabled: enabled);
      final home = _home;
      if (home != null) {
        _home = home.copyWith(
          driver: home.driver.copyWith(isAutoAcceptEnabled: isEnabled),
        );
      }
      _isUpdatingAutoAccept = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isUpdatingAutoAccept = false;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'Failed to update auto-accept';
      _isUpdatingAutoAccept = false;
      notifyListeners();
      return false;
    }
  }

  void setOnline(bool value) {
    _isOnline = value;
    _syncLocationHeartbeat();
    notifyListeners();
  }

  String _formatBhd(double amount) {
    return 'BHD ${amount.toStringAsFixed(3)}';
  }

  @override
  void dispose() {
    _locationHeartbeat?.cancel();
    super.dispose();
  }
}

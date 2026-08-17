import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:yjeek_driver/features/dashboard/model/home_model.dart';
import 'package:yjeek_driver/features/dashboard/service/dashboard_service.dart';
import 'package:yjeek_driver/l10n/l10n.dart';
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
  String get currentLocation =>
      _currentLocation == 'Fetching location...'
          ? L10n.tr('Fetching location...')
          : _currentLocation;
  DriverHomeModel? get home => _home;
  String? get error => _error;

  String get driverName => _home?.driver.displayName ?? L10n.tr('Driver');

  String get statusLabel =>
      _isOnline ? L10n.tr("You're online") : L10n.tr('Offline');

  int get tripsToday => _home?.today.ordersCount ?? 0;

  double get todayEarnings => _home?.today.totalEarnings ?? 0;

  String get todayEarningsLabel => _formatBhd(todayEarnings);

  String get onlineDurationLabel =>
      _home?.today.onlineDurationLabel.isNotEmpty == true
          ? _home!.today.onlineDurationLabel
          : '0m';

  int get scheduledOrdersCount => _home?.scheduledOrdersCount ?? 0;

  String get scheduledOrdersLabel => L10n.trParams(
        '{count} scheduled orders today',
        {'count': '$scheduledOrdersCount'},
      );

  int get unreadNotificationsCount => _home?.unreadNotificationsCount ?? 0;

  bool get hasUnreadNotifications => unreadNotificationsCount > 0;

  double get walletBalance => _home?.wallet.balance ?? 0;

  String get walletBalanceLabel => _formatBhd(walletBalance);

  double get pendingCashCollected =>
      _home?.wallet.pendingCashCollected ?? 0;

  String get pendingCashCollectedLabel => _formatBhd(pendingCashCollected);

  bool get hasOutstandingPodCash => pendingCashCollected > 0;

  bool get isAutoAcceptEnabled => _home?.driver.isAutoAcceptEnabled ?? false;

  String get autoAcceptTitle => isAutoAcceptEnabled
      ? L10n.tr('Auto-Accept is on')
      : L10n.tr('Auto-Accept is off');

  String get autoAcceptSubtitle => isAutoAcceptEnabled
      ? L10n.tr('Orders will be accepted automatically')
      : L10n.tr('Turn it on to get orders automatically');

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
      _error = L10n.tr('Failed to load home');
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
    if (ApiService.instance.accessToken == null ||
        ApiService.instance.accessToken!.isEmpty) {
      resetOnLogout();
      return;
    }
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
      final serviceEnabled =
          await _locationService.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw ApiException(
          L10n.tr('Turn on Location Services, then try Go online again'),
        );
      }

      var location = await _locationService.getCurrentMapLocation();
      if (location == null) {
        final permission = await _locationService.requestLocationPermission();
        final granted = permission == ph.PermissionStatus.granted ||
            permission == ph.PermissionStatus.limited ||
            permission == ph.PermissionStatus.provisional;
        if (!granted) {
          throw ApiException(
            permission == ph.PermissionStatus.permanentlyDenied
                ? L10n.tr(
                    'Location permission is required. Enable it in Settings.',
                  )
                : L10n.tr('Location permission is required to go online'),
          );
        }
        location = await _locationService.getCurrentMapLocation();
      }
      if (location == null) {
        throw ApiException(
          L10n.tr(
            'Could not get your GPS location. Try again outdoors or wait a moment.',
          ),
        );
      }

      final home = await _dashboardService.goOnline(
        latitude: location.latitude,
        longitude: location.longitude,
      );
      _home = home;
      // Go-online API succeeded — show online UI even if status string differs.
      _isOnline = true;
      _currentLocation =
          '${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)}';
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
      _error = L10n.tr('Failed to go online');
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
      _isOnline = false;
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
      _error = L10n.tr('Failed to go offline');
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
      _error = L10n.tr('Failed to update auto-accept');
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

  void resetOnLogout() {
    _locationHeartbeat?.cancel();
    _locationHeartbeat = null;
    _isOnline = false;
    _home = null;
    _error = null;
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

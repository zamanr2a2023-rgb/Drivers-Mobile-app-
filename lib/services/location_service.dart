import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:yjeek_driver/core/models/map_location.dart';

/// Real device location via Geolocator + permission_handler.
class LocationService {
  static Future<ph.PermissionStatus>? _permissionRequest;

  Future<bool> isLocationServiceEnabled() {
    return Geolocator.isLocationServiceEnabled();
  }

  Future<bool> hasLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// Requests location permission. Does not open Settings automatically —
  /// call [openAppSettings] only from an explicit user action (e.g. Retry).
  /// Concurrent callers share one in-flight request (iOS forbids parallel asks).
  Future<ph.PermissionStatus> requestLocationPermission() async {
    final existing = _permissionRequest;
    if (existing != null) return existing;

    final future = _requestLocationPermissionInternal();
    _permissionRequest = future;
    try {
      return await future;
    } finally {
      if (identical(_permissionRequest, future)) {
        _permissionRequest = null;
      }
    }
  }

  Future<ph.PermissionStatus> _requestLocationPermissionInternal() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return _toPermissionStatus(permission);
  }

  Future<bool> openAppSettings() => ph.openAppSettings();

  Future<MapLocation?> getCurrentMapLocation() async {
    final serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    final permitted = await hasLocationPermission();
    if (!permitted) return null;

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return MapLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        kind: MapLocationKind.driver,
        label: 'You',
      );
    } catch (_) {
      return null;
    }
  }

  /// Human-readable label for UI (legacy callers). Prefer [getCurrentMapLocation].
  Future<String> getCurrentLocation() async {
    final location = await getCurrentMapLocation();
    if (location == null) return 'Location unavailable';
    return '${location.latitude.toStringAsFixed(5)}, '
        '${location.longitude.toStringAsFixed(5)}';
  }

  Stream<Position> positionStream({
    int distanceFilterMeters = 15,
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilterMeters,
      ),
    );
  }

  ph.PermissionStatus _toPermissionStatus(LocationPermission permission) {
    switch (permission) {
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        return ph.PermissionStatus.granted;
      case LocationPermission.deniedForever:
        return ph.PermissionStatus.permanentlyDenied;
      case LocationPermission.unableToDetermine:
        return ph.PermissionStatus.denied;
      case LocationPermission.denied:
        return ph.PermissionStatus.denied;
    }
  }
}

import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Default driver pin (Shaikh Isa Ave, Manama).
const LatLng kBahrainFallbackLatLng =
    LatLng(26.220510224348875, 50.58472445399525);

/// When true, LocationService always reports [kBahrainFallbackLatLng]
/// instead of device GPS (useful while testing outside Bahrain).
const bool kUseFixedDriverLocation = true;

enum MapLocationKind { driver, pickup, dropoff, other }

class MapLocation {
  const MapLocation({
    required this.latitude,
    required this.longitude,
    this.label,
    this.kind = MapLocationKind.other,
  });

  final double latitude;
  final double longitude;
  final String? label;
  final MapLocationKind kind;

  LatLng get latLng => LatLng(latitude, longitude);

  bool get isValid =>
      latitude.isFinite &&
      longitude.isFinite &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180 &&
      !(latitude == 0 && longitude == 0);

  static MapLocation? tryParse({
    required dynamic latitude,
    required dynamic longitude,
    String? label,
    MapLocationKind kind = MapLocationKind.other,
  }) {
    final lat = _asDouble(latitude);
    final lng = _asDouble(longitude);
    if (lat == null || lng == null) return null;
    final location = MapLocation(
      latitude: lat,
      longitude: lng,
      label: label,
      kind: kind,
    );
    return location.isValid ? location : null;
  }

  static double? _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }
}

enum DriverMapState {
  initial,
  permissionRequired,
  loading,
  locationReady,
  mapReady,
  tracking,
  locationDisabled,
  permissionDenied,
  error,
}

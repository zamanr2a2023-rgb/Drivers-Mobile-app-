import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:yjeek_driver/core/models/map_location.dart';
import 'package:yjeek_driver/core/services/map_service.dart';
import 'package:yjeek_driver/core/widgets/current_location_button.dart';
import 'package:yjeek_driver/services/location_service.dart';

/// Reusable Google Map for driver screens. Replaces map placeholders.
class AppGoogleMap extends StatefulWidget {
  const AppGoogleMap({
    super.key,
    this.height,
    this.pickup,
    this.dropoff,
    this.routePoints = const [],
    this.trackDriver = true,
    this.showRecenterButton = true,
    this.routeColor = const Color(0xFF4CAF50),
    this.borderRadius,
    this.onStateChanged,
  });

  final double? height;
  final MapLocation? pickup;
  final MapLocation? dropoff;

  /// Backend-provided route points only. Never invent client-side routes.
  final List<LatLng> routePoints;

  final bool trackDriver;
  final bool showRecenterButton;
  final Color routeColor;
  final BorderRadius? borderRadius;
  final ValueChanged<DriverMapState>? onStateChanged;

  @override
  State<AppGoogleMap> createState() => _AppGoogleMapState();
}

class _AppGoogleMapState extends State<AppGoogleMap> with WidgetsBindingObserver {
  final LocationService _locationService = LocationService();

  GoogleMapController? _controller;
  DriverMapState _state = DriverMapState.initial;
  MapLocation? _driverLocation;
  bool _myLocationEnabled = false;
  bool _didInitialCameraMove = false;
  String? _message;
  StreamSubscription<Position>? _positionSub;
  bool _bootstrapping = false;
  Key _mapViewKey = UniqueKey();

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bootstrap();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || _bootstrapping) return;
    // Some Androids blank the platform view after Settings / background.
    // Remount the map surface, then re-bootstrap location.
    setState(() {
      _controller = null;
      _mapViewKey = UniqueKey();
      _didInitialCameraMove = false;
    });
    _bootstrap();
  }

  @override
  void didUpdateWidget(covariant AppGoogleMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pickup?.latitude != widget.pickup?.latitude ||
        oldWidget.pickup?.longitude != widget.pickup?.longitude ||
        oldWidget.dropoff?.latitude != widget.dropoff?.latitude ||
        oldWidget.dropoff?.longitude != widget.dropoff?.longitude ||
        oldWidget.routePoints != widget.routePoints) {
      _rebuildOverlays();
      _fitCamera(force: true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _positionSub?.cancel();
    // Do not dispose GoogleMapController — the GoogleMap widget owns it.
    _controller = null;
    super.dispose();
  }

  void _setState(DriverMapState next, {String? message}) {
    if (!mounted) return;
    setState(() {
      _state = next;
      if (message != null) _message = message;
    });
    widget.onStateChanged?.call(next);
  }

  Future<void> _bootstrap() async {
    if (_bootstrapping) return;
    _bootstrapping = true;
    _setState(DriverMapState.loading);
    _rebuildOverlays();

    try {
      final serviceEnabled = await _locationService.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _myLocationEnabled = false;
        _rebuildOverlays();
        _setState(
          DriverMapState.locationDisabled,
          message: 'Location services are turned off',
        );
        await _fitCamera(force: true);
        return;
      }

      final status = await _locationService.requestLocationPermission();
      if (!status.isGranted) {
        // Still show the base map (fallback camera). Never open Settings here —
        // that backgrounds the app mid-create and leaves a blank Google Map.
        _myLocationEnabled = false;
        _rebuildOverlays();
        _setState(
          status.isPermanentlyDenied
              ? DriverMapState.permissionDenied
              : DriverMapState.permissionRequired,
          message: status.isPermanentlyDenied
              ? 'Location permission permanently denied. Enable it in Settings.'
              : 'Location permission is required to show your position',
        );
        await _fitCamera(force: true);
        return;
      }

      _myLocationEnabled = true;
      final current = await _locationService.getCurrentMapLocation();
      if (!mounted) return;

      if (current != null) {
        _driverLocation = current;
        _setState(DriverMapState.locationReady);
      } else {
        _setState(
          DriverMapState.mapReady,
          message: 'Waiting for GPS…',
        );
      }

      _rebuildOverlays();
      await _fitCamera(force: true);

      if (widget.trackDriver) {
        await _startTracking();
      } else {
        _setState(DriverMapState.mapReady);
      }
    } finally {
      _bootstrapping = false;
    }
  }

  Future<void> _startTracking() async {
    await _positionSub?.cancel();
    _positionSub = _locationService.positionStream().listen(
      (position) {
        if (!mounted) return;
        final next = MapLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          kind: MapLocationKind.driver,
          label: 'You',
        );
        final shouldAnimateCamera = _driverLocation == null;
        _driverLocation = next;
        _rebuildOverlays();
        if (_state != DriverMapState.tracking) {
          _setState(DriverMapState.tracking);
        } else {
          setState(() {});
        }
        if (shouldAnimateCamera) {
          _fitCamera(force: true);
        }
      },
      onError: (_) {
        if (!mounted) return;
        // Keep last known location; do not crash.
      },
    );
  }

  void _rebuildOverlays() {
    final markers = <Marker>{};
    final driver = _driverLocation;
    if (driver != null && driver.isValid) {
      markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: driver.latLng,
          infoWindow: InfoWindow(title: driver.label ?? 'You'),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      );
    }

    final pickup = widget.pickup;
    if (pickup != null && pickup.isValid) {
      markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: pickup.latLng,
          infoWindow: InfoWindow(title: pickup.label ?? 'Pickup'),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );
    }

    final dropoff = widget.dropoff;
    if (dropoff != null && dropoff.isValid) {
      markers.add(
        Marker(
          markerId: const MarkerId('dropoff'),
          position: dropoff.latLng,
          infoWindow: InfoWindow(title: dropoff.label ?? 'Drop-off'),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        ),
      );
    }

    final polylines = <Polyline>{};
    if (widget.routePoints.length >= 2) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: widget.routePoints,
          color: widget.routeColor,
          width: 4,
        ),
      );
    }

    _markers = markers;
    _polylines = polylines;
  }

  List<LatLng> get _allPoints {
    final points = <LatLng>[
      ...widget.routePoints,
    ];
    if (_driverLocation?.isValid == true) {
      points.add(_driverLocation!.latLng);
    }
    if (widget.pickup?.isValid == true) points.add(widget.pickup!.latLng);
    if (widget.dropoff?.isValid == true) points.add(widget.dropoff!.latLng);
    return points;
  }

  Future<void> _fitCamera({bool force = false}) async {
    final controller = _controller;
    if (controller == null || !mounted) return;

    final points = _allPoints;
    try {
      if (points.length >= 2) {
        final bounds = MapService.boundsFor(points);
        if (bounds != null) {
          await controller.animateCamera(
            CameraUpdate.newLatLngBounds(bounds, 56),
          );
          _didInitialCameraMove = true;
          return;
        }
      }

      final target = _driverLocation?.isValid == true
          ? _driverLocation!.latLng
          : kBahrainFallbackLatLng;

      if (!force && _didInitialCameraMove && _driverLocation != null) {
        return;
      }

      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
              target: target, zoom: _driverLocation != null ? 15 : 12),
        ),
      );
      _didInitialCameraMove = true;
    } catch (_) {
      // Controller may be disposed during async gap.
    }
  }

  Future<void> _onPermissionRetry() async {
    if (_state == DriverMapState.permissionDenied) {
      await _locationService.openAppSettings();
      return;
    }
    await _bootstrap();
  }

  Future<void> _onRecenter() async {
    if (_state == DriverMapState.permissionDenied ||
        _state == DriverMapState.permissionRequired ||
        _state == DriverMapState.locationDisabled) {
      await _onPermissionRetry();
      return;
    }

    final current = await _locationService.getCurrentMapLocation();
    if (!mounted) return;
    if (current == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Unable to get current location'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }

    setState(() {
      _driverLocation = current;
      _rebuildOverlays();
    });
    await _fitCamera(force: true);
  }

  CameraPosition get _initialCamera {
    final target = _driverLocation?.isValid == true
        ? _driverLocation!.latLng
        : (widget.pickup?.isValid == true
            ? widget.pickup!.latLng
            : (widget.dropoff?.isValid == true
                ? widget.dropoff!.latLng
                : kBahrainFallbackLatLng));
    return CameraPosition(target: target, zoom: 14);
  }

  @override
  Widget build(BuildContext context) {
    final map = GoogleMap(
      key: _mapViewKey,
      initialCameraPosition: _initialCamera,
      myLocationEnabled: _myLocationEnabled,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      compassEnabled: false,
      mapToolbarEnabled: false,
      markers: _markers,
      polylines: _polylines,
      onMapCreated: (controller) async {
        _controller = controller;
        _setState(
          _driverLocation != null ? DriverMapState.mapReady : _state,
        );
        await _fitCamera(force: true);
      },
    );

    Widget body = Stack(
      children: [
        Positioned.fill(child: map),
        if (_message != null &&
            (_state == DriverMapState.permissionRequired ||
                _state == DriverMapState.permissionDenied ||
                _state == DriverMapState.locationDisabled ||
                _state == DriverMapState.error ||
                _state == DriverMapState.loading))
          Positioned(
            left: 12,
            right: 12,
            top: 12,
            child: Material(
              color: Colors.white.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    if (_state == DriverMapState.loading)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      const Icon(Icons.info_outline,
                          size: 18, color: Color(0xFF757575)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _message!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF424242),
                        ),
                      ),
                    ),
                    if (_state == DriverMapState.permissionDenied ||
                        _state == DriverMapState.permissionRequired ||
                        _state == DriverMapState.locationDisabled)
                      TextButton(
                        onPressed: _onPermissionRetry,
                        child: const Text('Retry'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        if (widget.showRecenterButton)
          Positioned(
            right: 12,
            bottom: 12,
            child: CurrentLocationButton(onPressed: _onRecenter),
          ),
      ],
    );

    if (widget.borderRadius != null) {
      body = ClipRRect(borderRadius: widget.borderRadius!, child: body);
    }

    if (widget.height != null) {
      return SizedBox(
        width: double.infinity,
        height: widget.height,
        child: body,
      );
    }

    return SizedBox(width: double.infinity, child: body);
  }
}

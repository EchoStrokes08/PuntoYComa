import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../../domain/entities/trip.dart';
import '../../domain/services/platform_contracts.dart';

/// Raised when the watch stream cannot start because the OS permission
/// for location is denied for this session or forever.
class PermissionRejectedException implements Exception {
  const PermissionRejectedException(this.permission);

  final LocationPermission permission;

  @override
  String toString() => 'PermissionRejectedException($permission)';
}

/// Implementation of [LocationSource] on top of `geolocator`.
/// Battery and background behavior stays out of the pure domain: this class
/// only translates geolocator positions into domain [LocationSample]s.
class GeolocatorLocationSource implements LocationSource {
  const GeolocatorLocationSource();

  @override
  Stream<LocationSample> watch(LocationTrackingProfile profile) {
    return Geolocator.getPositionStream(locationSettings: _settingsFor(profile))
        .map(_toSample);
  }

  /// Returns true only when the app may obtain updates right now.
  /// Never throws: callers decide what to do on denial.
  Future<bool> ensurePermission({bool requestIfDenied = true}) async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied && requestIfDenied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return false;
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  LocationSettings _settingsFor(LocationTrackingProfile profile) =>
      switch (profile) {
        LocationTrackingProfile.passive => const LocationSettings(
          accuracy: LocationAccuracy.low,
          distanceFilter: 50,
        ),
        LocationTrackingProfile.balanced => const LocationSettings(
          accuracy: LocationAccuracy.medium,
          distanceFilter: 20,
        ),
        LocationTrackingProfile.highAccuracy => const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 5,
        ),
      };

  LocationSample _toSample(Position position) {
    final rawSpeed = position.speed;
    final speed = rawSpeed.isFinite ? rawSpeed : 0.0;
    return LocationSample(
      position: GeoPoint(
        position.latitude,
        position.longitude,
        accuracyMeters: position.accuracy.isFinite ? position.accuracy : 0,
      ),
      speedMetersPerSecond: speed.clamp(0, 45).toDouble(),
      capturedAt: position.timestamp,
    );
  }
}

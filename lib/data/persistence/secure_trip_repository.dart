import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/entities/trip.dart';
import '../../domain/services/platform_contracts.dart';

/// Cryptographically protected storage available before trust is established.
class SecureTripRepository implements TripRepository {
  SecureTripRepository({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();
  static const _key = 'punto_y_coma.active_trip.v1';
  final FlutterSecureStorage _storage;

  @override
  Future<void> saveActive(Trip trip) =>
      _storage.write(key: _key, value: jsonEncode(TripMapper.toJson(trip)));

  @override
  Future<Trip?> readActive() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) return null;
    try {
      return TripMapper.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } on FormatException catch (_) {
      return null;
    }
  }

  @override
  Future<void> clearActive() => _storage.delete(key: _key);
}

/// Serializes the immutable domain [Trip] without leaking the read/write
/// format into the domain layer.
class TripMapper {
  const TripMapper._();

  static Map<String, dynamic> toJson(Trip trip) => <String, dynamic>{
    'id': trip.id,
    'destinationLatitude': trip.destination.latitude,
    'destinationLongitude': trip.destination.longitude,
    'destinationAccuracyMeters': trip.destination.accuracyMeters,
    'mode': trip.mode.name,
    'status': trip.status.name,
    'alertLeadTimeMs': trip.alertLeadTime.inMilliseconds,
  };

  static Trip fromJson(Map<String, dynamic> json) => Trip(
    id: json['id'] as String,
    destination: GeoPoint(
      (json['destinationLatitude'] as num).toDouble(),
      (json['destinationLongitude'] as num).toDouble(),
      accuracyMeters:
          (json['destinationAccuracyMeters'] as num?)?.toDouble() ?? 0,
    ),
    mode: TransportMode.values.firstWhere(
      (value) => value.name == json['mode'],
      orElse: () => TransportMode.bus,
    ),
    status: TripStatus.values.firstWhere(
      (value) => value.name == json['status'],
      orElse: () => TripStatus.draft,
    ),
    alertLeadTime:
        Duration(milliseconds: (json['alertLeadTimeMs'] as num?)?.toInt() ?? 0),
  );
}

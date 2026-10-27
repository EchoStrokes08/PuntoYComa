import 'dart:convert';

import '../../domain/entities/trip.dart';
import '../../domain/services/secure_storage_contracts.dart';
import '../../domain/services/trip_history_contracts.dart';
import 'flutter_secure_storage_adapter.dart';

/// Serializa/deserializa [Trip] para el historial local (recientes/favoritos).
/// El formato es independiente del viaje activo para evitar colisiones de clave.
class _TripHistoryMapper {
  const _TripHistoryMapper();

  static Map<String, dynamic> toJson(Trip trip) => <String, dynamic>{
    'id': trip.id,
    'destinationLatitude': trip.destination.latitude,
    'destinationLongitude': trip.destination.longitude,
    'destinationAccuracyMeters': trip.destination.accuracyMeters,
    'mode': trip.mode.name,
    'status': trip.status.name,
    'alertLeadTimeMs': trip.alertLeadTime.inMilliseconds,
    'favorited': false,
    'savedAtMs': DateTime.now().millisecondsSinceEpoch,
  };

  static Trip fromJson(Map<String, dynamic> json) => Trip(
    id: json['id'] as String,
    destination: GeoPoint(
      (json['destinationLatitude'] as num).toDouble(),
      (json['destinationLongitude'] as num).toDouble(),
      accuracyMeters: (json['destinationAccuracyMeters'] as num?)?.toDouble() ?? 0,
    ),
    mode: TransportMode.values.firstWhere(
      (value) => value.name == json['mode'],
      orElse: () => TransportMode.bus,
    ),
    status: TripStatus.values.firstWhere(
      (value) => value.name == json['status'],
      orElse: () => TripStatus.draft,
    ),
    alertLeadTime: Duration(
      milliseconds: (json['alertLeadTimeMs'] as num?)?.toInt() ?? 0,
    ),
  );
}

/// Repositorio de historial local: recientes y favoritos cifrados.
///
/// Cada entrada se guarda bajo una clave compuesta por tipo + id del viaje.
/// Los recientes mantienen un índice ordenado por timestamp de guardado.
class TripHistoryRepositoryImpl implements TripHistoryRepository {
  TripHistoryRepositoryImpl({SecureStorage? storage})
      : _storage = storage ?? FlutterSecureStorageAdapter();

  static const _recentPrefix = 'punto_y_coma.recent.';
  static const _favoritePrefix = 'punto_y_coma.favorite.';
  static const _recentsIndexKey = 'punto_y_coma.recents_index.v1';
  static const _maxRecents = 50;

  final SecureStorage _storage;

  @override
  Future<void> saveRecent(Trip trip) async {
    await _writeTrip(_recentPrefix, trip);
    await _appendToIndex(trip.id);
    await _trimRecents();
  }

  @override
  Future<List<Trip>> getRecents({int limit = 10}) async {
    final indexRaw = await _storage.read(key: _recentsIndexKey);
    if (indexRaw == null) return const [];
    try {
      final ids = (jsonDecode(indexRaw) as List<dynamic>).cast<String>();
      final trips = <Trip>[];
      for (final id in ids.reversed.take(limit)) {
        final trip = await _readTrip(_recentPrefix, id);
        if (trip != null) trips.add(trip);
      }
      return trips;
    } on FormatException {
      return const [];
    }
  }

  @override
  Future<void> toggleFavorite(String tripId) async {
    final currently = await isFavorite(tripId);
    if (currently) {
      await _storage.delete(key: '$_favoritePrefix$tripId');
    } else {
      // Leer el viaje desde recientes para guardar el favorito con sus datos.
      final trip = await _readTrip(_recentPrefix, tripId);
      if (trip != null) {
        await _writeTrip(_favoritePrefix, trip);
      }
    }
  }

  @override
  Future<List<Trip>> getFavorites() async {
    final all = await _storage.readAll();
    final favorites = <Trip>[];
    for (final entry in all.entries) {
      if (!entry.key.startsWith(_favoritePrefix)) continue;
      try {
        final trip = _TripHistoryMapper.fromJson(
          jsonDecode(entry.value) as Map<String, dynamic>,
        );
        favorites.add(trip);
      } catch (_) {
        // Ignorar entradas corruptas del historial de favoritos.
      }
    }
    favorites.sort((a, b) => a.id.compareTo(b.id));
    return favorites;
  }

  @override
  Future<bool> isFavorite(String tripId) async {
    final raw = await _storage.read(key: '$_favoritePrefix$tripId');
    return raw != null;
  }

  @override
  Future<void> clearRecents() async {
    final all = await _storage.readAll();
    final keysToDelete = <String>[];
    for (final key in all.keys) {
      if (key.startsWith(_recentPrefix) || key == _recentsIndexKey) {
        keysToDelete.add(key);
      }
    }
    for (final key in keysToDelete) {
      await _storage.delete(key: key);
    }
  }

  Future<void> _writeTrip(String prefix, Trip trip) async {
    await _storage.write(
      key: '$prefix${trip.id}',
      value: jsonEncode(_TripHistoryMapper.toJson(trip)),
    );
  }

  Future<Trip?> _readTrip(String prefix, String id) async {
    final raw = await _storage.read(key: '$prefix$id');
    if (raw == null) return null;
    try {
      return _TripHistoryMapper.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } on FormatException {
      return null;
    }
  }

  Future<void> _appendToIndex(String tripId) async {
    final raw = await _storage.read(key: _recentsIndexKey);
    final List<String> ids = [];
    if (raw != null) {
      try {
        ids.addAll((jsonDecode(raw) as List<dynamic>).cast<String>());
      } on FormatException {
        // Índice corrupto: empezar desde cero.
      }
    }
    ids.remove(tripId);
    ids.add(tripId);
    await _storage.write(
      key: _recentsIndexKey,
      value: jsonEncode(ids),
    );
  }

  Future<void> _trimRecents() async {
    final raw = await _storage.read(key: _recentsIndexKey);
    if (raw == null) return;
    try {
      final ids = (jsonDecode(raw) as List<dynamic>).cast<String>();
      if (ids.length <= _maxRecents) return;
      final toRemove = ids.take(ids.length - _maxRecents);
      for (final id in toRemove) {
        await _storage.delete(key: '$_recentPrefix$id');
      }
      await _storage.write(
        key: _recentsIndexKey,
        value: jsonEncode(ids.skip(ids.length - _maxRecents).toList()),
      );
    } on FormatException {
      // Índice corrupto: no se puede trimar.
    }
  }
}

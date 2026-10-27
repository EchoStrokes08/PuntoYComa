import 'dart:convert';

import '../../domain/entities/trip.dart';
import '../../domain/services/arrival_prediction.dart';
import '../../domain/services/secure_storage_contracts.dart';
import '../persistence/flutter_secure_storage_adapter.dart';
import '../persistence/in_memory_secure_storage.dart';

/// Una parada de tránsito cacheada localmente (primer paquete GTFS simplificado).
///
/// Las coordenadas nunca salen del dispositivo: este caché solo sirve para
/// calcular ETA y radio de alerta sin depender de red.
class CachedStop {
  const CachedStop({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.mode,
    this.routeId,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final TransportMode mode;
  final String? routeId;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'latitude': latitude,
    'longitude': longitude,
    'mode': mode.name,
    if (routeId != null) 'routeId': routeId,
  };

  static CachedStop fromJson(Map<String, dynamic> json) => CachedStop(
    id: json['id'] as String,
    name: json['name'] as String,
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    mode: TransportMode.values.firstWhere(
      (value) => value.name == json['mode'],
      orElse: () => TransportMode.bus,
    ),
    routeId: json['routeId'] as String?,
  );
}

/// [SecureStorage], [FlutterSecureStorageAdapter] and [InMemorySecureStorage]
/// are defined in shared modules (domain/services/secure_storage_contracts.dart
/// and data/persistence/flutter_secure_storage_adapter.dart) so they can be
/// reused by both LocalStopCache and TripHistoryRepositoryImpl.

/// Caché local de paradas por ruta. Persistido cifrado en el dispositivo.
///
/// Operaciones:
/// - [saveStopsForRoute]: guarda el paquete de paradas de una ruta seleccionada.
/// - [getStopsForRoute]: recupera las paradas cacheadas de una ruta.
/// - [nearbyStops]: devuelve paradas cercanas a una coordenada (radio en metros),
///   útil para precargar sin internet.
class LocalStopCache {
  final SecureStorage _storage;

  LocalStopCache({SecureStorage? storage})
      : _storage = storage ?? FlutterSecureStorageAdapter();

  static const _prefix = 'punto_y_coma.stop.';
  static const _allRouteIndexKey = 'punto_y_coma.stop_index.v1';

  /// Guarda las [stops] de una [routeId], sobrescribiendo cualquier caché previa.
  Future<void> saveStopsForRoute(String routeId, List<CachedStop> stops) async {
    final key = '$_prefix$routeId';
    await _storage.write(
      key: key,
      value: jsonEncode(stops.map((s) => s.toJson()).toList()),
    );
    await _recordRoute(routeId);
  }

  /// Recupera las paradas cacheadas de [routeId]. Vacío si no hay caché.
  Future<List<CachedStop>> getStopsForRoute(String routeId) async {
    final key = '$_prefix$routeId';
    final raw = await _storage.read(key: key);
    if (raw == null) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .cast<Map<String, dynamic>>()
          .map(CachedStop.fromJson)
          .toList();
    } on FormatException {
      return const [];
    }
  }

  /// Elimina el caché de paradas de [routeId].
  Future<void> clearRoute(String routeId) async {
    await _storage.delete(key: '$_prefix$routeId');
    await _forgetRoute(routeId);
  }

  /// Devuelve paradas cacheadas (de cualquier ruta) dentro de [radiusMeters]
  /// de [center], ordenadas de más cercana a más lejana, hasta [limit].
  Future<List<CachedStop>> nearbyStops(
    GeoPoint center, {
    required double radiusMeters,
    int limit = 20,
  }) async {
    final all = await _storage.readAll();
    final found = <CachedStop>[];
    for (final entry in all.entries) {
      if (!entry.key.startsWith(_prefix)) continue;
      try {
        final list = jsonDecode(entry.value) as List<dynamic>;
        for (final item in list.cast<Map<String, dynamic>>()) {
          final stop = CachedStop.fromJson(item);
          final d = ArrivalPrediction.distanceMeters(
            center.latitude,
            center.longitude,
            stop.latitude,
            stop.longitude,
          );
          if (d <= radiusMeters) found.add(stop);
        }
      } catch (_) {
        // Ignorar entradas corruptas.
      }
    }
    found.sort((a, b) {
      final da = ArrivalPrediction.distanceMeters(
        center.latitude, center.longitude, a.latitude, a.longitude,
      );
      final db = ArrivalPrediction.distanceMeters(
        center.latitude, center.longitude, b.latitude, b.longitude,
      );
      return da.compareTo(db);
    });
    return found.take(limit).toList();
  }

  /// Borra todo el caché de paradas.
  Future<void> clearAll() async {
    final all = await _storage.readAll();
    final keysToDelete = <String>[];
    for (final key in all.keys) {
      if (key.startsWith(_prefix) || key == _allRouteIndexKey) {
        keysToDelete.add(key);
      }
    }
    for (final key in keysToDelete) {
      await _storage.delete(key: key);
    }
  }

  Future<void> _recordRoute(String routeId) async {
    final raw = await _storage.read(key: _allRouteIndexKey);
    final Set<String> routes = {};
    if (raw != null) {
      try {
        routes.addAll((jsonDecode(raw) as List<dynamic>).cast<String>());
      } catch (_) {}
    }
    routes.add(routeId);
    await _storage.write(
      key: _allRouteIndexKey,
      value: jsonEncode(routes.toList()),
    );
  }

  Future<void> _forgetRoute(String routeId) async {
    final raw = await _storage.read(key: _allRouteIndexKey);
    if (raw == null) return;
    try {
      final routes = (jsonDecode(raw) as List<dynamic>).cast<String>();
      routes.remove(routeId);
      await _storage.write(
        key: _allRouteIndexKey,
        value: jsonEncode(routes),
      );
    } catch (_) {}
  }
}

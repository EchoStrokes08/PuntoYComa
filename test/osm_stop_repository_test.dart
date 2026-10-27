import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:punto_y_coma/data/persistence/in_memory_secure_storage.dart';
import 'package:punto_y_coma/data/routing/local_stop_cache.dart';
import 'package:punto_y_coma/data/routing/osm_stop_repository.dart';
import 'package:punto_y_coma/domain/entities/trip.dart';
import 'package:punto_y_coma/presentation/view_models/destination_view_model.dart';

const _origen = GeoPoint(4.66801, -74.05193);

String _overpassJson() => jsonEncode({
  'elements': [
    {
      'type': 'node',
      'id': 1,
      'lat': 4.6690,
      'lon': -74.0510,
      'tags': {'name': 'Calle 76', 'highway': 'bus_stop'},
    },
    {
      'type': 'node',
      'id': 2,
      'lat': 4.6700,
      'lon': -74.0500,
      'tags': {'name': 'Estación Centro', 'railway': 'station', 'station': 'subway'},
    },
    {
      'type': 'node',
      'id': 3,
      'lat': 4.6710,
      'lon': -74.0490,
      'tags': {'name': 'Halt Norte', 'railway': 'halt'},
    },
    // Sin nombre: se ignora.
    {
      'type': 'node',
      'id': 4,
      'lat': 4.6720,
      'lon': -74.0480,
      'tags': {'highway': 'bus_stop'},
    },
    // Sin coordenadas: se ignora.
    {
      'type': 'node',
      'id': 5,
      'tags': {'name': 'Fantasma', 'highway': 'bus_stop'},
    },
    // Duplicado del id 1: se ignora.
    {
      'type': 'node',
      'id': 1,
      'lat': 4.6690,
      'lon': -74.0510,
      'tags': {'name': 'Calle 76', 'highway': 'bus_stop'},
    },
  ],
});

/// Respuesta como la de Overpass: bytes UTF-8 reales (con tildes).
/// `http.Response(texto, 200)` codificaría en latin1 y no representa al servidor.
http.Response _ok() => http.Response.bytes(
  utf8.encode(_overpassJson()),
  200,
  headers: const {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  group('OsmStopRepository', () {
    test('cellCenter redondea al centro de la celda de ~1 km', () {
      final c = OsmStopRepository.cellCenter(_origen);
      expect(c.latitude, closeTo(4.665, 1e-9));
      expect(c.longitude, closeTo(-74.055, 1e-9));
    });

    test('la clave de caché es igual dentro de la misma celda', () {
      final a = OsmStopRepository.cacheKey(const GeoPoint(4.6601, -74.0501));
      final b = OsmStopRepository.cacheKey(const GeoPoint(4.6699, -74.0599));
      final c = OsmStopRepository.cacheKey(const GeoPoint(4.6701, -74.0501));
      expect(a, b);
      expect(a, isNot(c));
    });

    test('parseResponse mapea modos y descarta elementos inválidos', () {
      final stops = OsmStopRepository.parseResponse(_overpassJson());
      expect(stops.map((s) => s.id), ['osm:1', 'osm:2', 'osm:3']);
      expect(stops[0].mode, TransportMode.bus);
      expect(stops[1].mode, TransportMode.metro);
      expect(stops[2].mode, TransportMode.train);
      expect(stops[0].name, 'Calle 76');
    });

    test('parseResponse tolera respuestas vacías o con otra forma', () {
      expect(OsmStopRepository.parseResponse('{}'), isEmpty);
      expect(OsmStopRepository.parseResponse('[]'), isEmpty);
      expect(OsmStopRepository.parseResponse('{"elements": 3}'), isEmpty);
    });

    test('fetchNearby NO envía la posición exacta, solo el centro de celda',
        () async {
      late String query;
      final client = MockClient((request) async {
        query = request.bodyFields['data']!;
        return _ok();
      });
      final repo = OsmStopRepository(client: client);

      final stops = await repo.fetchNearby(_origen);

      expect(stops, hasLength(3));
      expect(query, contains('4.66500,-74.05500'));
      expect(query, isNot(contains('4.66801')));
      expect(query, isNot(contains('-74.05193')));
    });

    test('fetchNearby lanza si el servidor responde con error', () async {
      final client = MockClient((_) async => http.Response('busy', 429));
      final repo = OsmStopRepository(client: client);
      expect(() => repo.fetchNearby(_origen), throwsA(isA<http.ClientException>()));
    });
  });

  group('DestinationViewModel.loadNearbyFromOrigin', () {
    late LocalStopCache cache;

    setUp(() => cache = LocalStopCache(storage: InMemorySecureStorage()));

    test('trae paradas reales, las guarda en caché y las muestra', () async {
      final repo = OsmStopRepository(
        client: MockClient((_) async => _ok()),
      );
      final vm = DestinationViewModel(
        stopCache: cache,
        remoteStops: repo,
        resolveOrigin: () async => _origen,
      );

      await vm.loadNearbyFromOrigin();

      expect(vm.origin, isNotNull);
      expect(vm.nearbyStops.map((s) => s.name), contains('Calle 76'));
      expect(vm.mapStops, isNotEmpty);
      // Quedó persistido para uso sin internet.
      final cached = await cache.getStopsForRoute(
        OsmStopRepository.cacheKey(_origen),
      );
      expect(cached, hasLength(3));
    });

    test('sin red usa lo que ya había en caché', () async {
      await cache.saveStopsForRoute(OsmStopRepository.cacheKey(_origen), [
        const CachedStop(
          id: 'osm:9',
          name: 'Parada guardada',
          latitude: 4.6690,
          longitude: -74.0510,
          mode: TransportMode.bus,
        ),
      ]);
      final repo = OsmStopRepository(
        client: MockClient((_) async => throw http.ClientException('offline')),
      );
      final vm = DestinationViewModel(
        stopCache: cache,
        remoteStops: repo,
        resolveOrigin: () async => _origen,
      );

      await vm.loadNearbyFromOrigin();

      expect(vm.nearbyStops.single.name, 'Parada guardada');
    });

    test('si no hay origen no consulta nada', () async {
      var llamadas = 0;
      final repo = OsmStopRepository(
        client: MockClient((_) async {
          llamadas++;
          return _ok();
        }),
      );
      final vm = DestinationViewModel(
        stopCache: cache,
        remoteStops: repo,
        resolveOrigin: () async => null,
      );

      await vm.loadNearbyFromOrigin();

      expect(llamadas, 0);
      expect(vm.origin, isNull);
      expect(vm.mapStops, isEmpty);
    });
  });
}

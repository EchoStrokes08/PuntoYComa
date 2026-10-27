import 'package:flutter_test/flutter_test.dart';

import 'package:punto_y_coma/data/persistence/in_memory_secure_storage.dart';
import 'package:punto_y_coma/data/routing/local_stop_cache.dart';
import 'package:punto_y_coma/domain/entities/trip.dart';

void main() {
  const centro = GeoPoint(4.6680, -74.0519);

  late LocalStopCache cache;
  late InMemorySecureStorage storage;

  setUp(() {
    storage = InMemorySecureStorage();
    cache = LocalStopCache(storage: storage);
  });

  tearDown(() async {
    await cache.clearAll();
  });

  List<CachedStop> rutaA() => [
    CachedStop(
      id: 'stop-1',
      name: 'Calle 76',
      latitude: 4.6680,
      longitude: -74.0519,
      mode: TransportMode.metro,
      routeId: 'ruta-A',
    ),
    CachedStop(
      id: 'stop-2',
      name: 'Calle 85',
      latitude: 4.6900,
      longitude: -74.0519,
      mode: TransportMode.metro,
      routeId: 'ruta-A',
    ),
    CachedStop(
      id: 'stop-3',
      name: 'Universidades',
      latitude: 4.6020,
      longitude: -74.0647,
      mode: TransportMode.bus,
      routeId: 'ruta-A',
    ),
  ];

  test('guardar y recuperar paradas de una ruta', () async {
    final paradas = rutaA();
    await cache.saveStopsForRoute('ruta-A', paradas);

    final recuperadas = await cache.getStopsForRoute('ruta-A');
    expect(recuperadas.length, 3);
    expect(recuperadas[0].name, 'Calle 76');
    expect(recuperadas[1].name, 'Calle 85');
    expect(recuperadas[2].mode, TransportMode.bus);
  });

  test('ruta sin caché devuelve lista vacía', () async {
    final recuperadas = await cache.getStopsForRoute('ruta-inexistente');
    expect(recuperadas, isEmpty);
  });

  test('sobrescribir caché de una ruta', () async {
    await cache.saveStopsForRoute('ruta-A', rutaA().take(1).toList());
    await cache.saveStopsForRoute('ruta-A', rutaA());

    final recuperadas = await cache.getStopsForRoute('ruta-A');
    expect(recuperadas.length, 3);
  });

  test('borrar caché de una ruta', () async {
    await cache.saveStopsForRoute('ruta-A', rutaA());
    await cache.clearRoute('ruta-A');

    final recuperadas = await cache.getStopsForRoute('ruta-A');
    expect(recuperadas, isEmpty);
  });

  test('nearbyStops devuelve paradas dentro del radio, ordenadas por distancia', () async {
    await cache.saveStopsForRoute('ruta-A', rutaA());

    // 4.6680, -74.0519 es el centro mismo: stop-1 está a 0 m.
    final cercanas = await cache.nearbyStops(
      centro,
      radiusMeters: 5000, // 5 km cubre stop-1 y stop-2 (~2.4 km)
    );

    expect(cercanas.length, 2);
    expect(cercanas.first.name, 'Calle 76'); // 0 m, la más cercana
    expect(cercanas.last.name, 'Calle 85'); // ~2.4 km
  });

  test('nearbyStops excluye paradas fuera del radio', () async {
    await cache.saveStopsForRoute('ruta-A', rutaA());

    final cercanas = await cache.nearbyStops(
      centro,
      radiusMeters: 100, // solo stop-1 está a 0 m
    );

    expect(cercanas.length, 1);
    expect(cercanas.first.name, 'Calle 76');
  });

  test('nearbyStops respeta el límite', () async {
    await cache.saveStopsForRoute('ruta-A', rutaA());

    final cercanas = await cache.nearbyStops(
      centro,
      radiusMeters: 100000, // 100 km cubre todo
      limit: 2,
    );

    expect(cercanas.length, 2);
  });

  test('clearAll borra todo el caché', () async {
    await cache.saveStopsForRoute('ruta-A', rutaA());
    await cache.saveStopsForRoute('ruta-B', rutaA().take(1).toList());

    await cache.clearAll();

    expect(await cache.getStopsForRoute('ruta-A'), isEmpty);
    expect(await cache.getStopsForRoute('ruta-B'), isEmpty);
  });
}

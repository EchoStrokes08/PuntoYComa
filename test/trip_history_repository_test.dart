import 'package:flutter_test/flutter_test.dart';

import 'package:punto_y_coma/data/persistence/in_memory_secure_storage.dart';
import 'package:punto_y_coma/data/persistence/trip_history_repository.dart';
import 'package:punto_y_coma/domain/entities/trip.dart';

void main() {
  late TripHistoryRepositoryImpl repository;
  late InMemorySecureStorage storage;

  setUp(() {
    storage = InMemorySecureStorage();
    repository = TripHistoryRepositoryImpl(storage: storage);
  });

  final t1 = Trip(
    id: 'trip-1',
    destination: GeoPoint(4.6680, -74.0519, accuracyMeters: 10),
    mode: TransportMode.metro,
    status: TripStatus.armed,
    alertLeadTime: Duration(minutes: 4),
  );
  final t2 = Trip(
    id: 'trip-2',
    destination: GeoPoint(4.6045, -74.0658, accuracyMeters: 10),
    mode: TransportMode.bus,
    status: TripStatus.completed,
    alertLeadTime: Duration(minutes: 3),
  );

  test('guardar y recuperar recientes', () async {
    await repository.saveRecent(t1);
    await repository.saveRecent(t2);

    final recents = await repository.getRecents();
    expect(recents.length, 2);
    expect(recents.first.id, 'trip-2'); // más reciente primero
    expect(recents.last.id, 'trip-1');
  });

  test('getRecents respeta el límite', () async {
    await repository.saveRecent(t1);
    await repository.saveRecent(t2);

    final recents = await repository.getRecents(limit: 1);
    expect(recents.length, 1);
    expect(recents.first.id, 'trip-2');
  });

  test('toggleFavorite y isFavorite', () async {
    await repository.saveRecent(t1);

    expect(await repository.isFavorite('trip-1'), isFalse);
    await repository.toggleFavorite('trip-1');
    expect(await repository.isFavorite('trip-1'), isTrue);
    await repository.toggleFavorite('trip-1');
    expect(await repository.isFavorite('trip-1'), isFalse);
  });

  test('getFavorites devuelve solo favoritos', () async {
    await repository.saveRecent(t1);
    await repository.saveRecent(t2);
    await repository.toggleFavorite('trip-1');

    final favorites = await repository.getFavorites();
    expect(favorites.length, 1);
    expect(favorites.first.id, 'trip-1');
  });

  test('clearRecents borra todo', () async {
    await repository.saveRecent(t1);
    await repository.saveRecent(t2);
    await repository.toggleFavorite('trip-1');

    await repository.clearRecents();

    final recents = await repository.getRecents();
    expect(recents, isEmpty);
    // Los favoritos no se borran con clearRecents.
    expect(await repository.isFavorite('trip-1'), isTrue);
  });
}

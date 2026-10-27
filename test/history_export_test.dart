import 'package:flutter_test/flutter_test.dart';

import 'package:punto_y_coma/domain/entities/trip.dart';
import 'package:punto_y_coma/domain/services/history_export.dart';

void main() {
  Trip trip({
    String id = 'trip-1',
    double latitude = 4.6680,
    double longitude = -74.0519,
    TransportMode mode = TransportMode.metro,
    int minutes = 4,
  }) =>
      Trip(
        id: id,
        destination: GeoPoint(latitude, longitude),
        mode: mode,
        status: TripStatus.completed,
        alertLeadTime: Duration(minutes: minutes),
      );

  final generatedAt = DateTime(2026, 10, 25, 7, 5);

  test('resume los viajes con modo, margen y zona aproximada', () {
    final summary = HistoryExporter.buildSummary(
      [trip(), trip(id: 'trip-2', mode: TransportMode.bus, minutes: 8)],
      generatedAt: generatedAt,
    );

    expect(summary, contains('25/10/2026 07:05'));
    expect(summary, contains('Total: 2 viajes'));
    expect(summary, contains('Metro · 4 min de anticipación'));
    expect(summary, contains('Bus · 8 min de anticipación'));
    expect(summary, contains('zona 4.67, -74.05'));
  });

  test('nunca exporta coordenadas precisas', () {
    final summary = HistoryExporter.buildSummary(
      [trip(latitude: 4.668012, longitude: -74.051934)],
      generatedAt: generatedAt,
    );

    expect(summary, isNot(contains('4.668012')));
    expect(summary, isNot(contains('-74.051934')));
    expect(summary, contains('zona 4.67, -74.05'));
    expect(summary, contains('~1 km'));
  });

  test('elimina viajes duplicados por identificador', () {
    final summary = HistoryExporter.buildSummary(
      [trip(), trip()],
      generatedAt: generatedAt,
    );

    expect(summary, contains('Total: 1 viaje'));
    expect('1.'.allMatches(summary).length, 1);
  });

  test('explica el estado vacío sin fallar', () {
    final summary = HistoryExporter.buildSummary(
      const [],
      generatedAt: generatedAt,
    );

    expect(summary, contains('Total: 0 viajes'));
    expect(summary, contains('Todavía no hay viajes guardados.'));
  });
}

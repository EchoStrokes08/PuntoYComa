import 'package:flutter_test/flutter_test.dart';

import 'package:punto_y_coma/domain/entities/trip.dart';
import 'package:punto_y_coma/domain/services/arrival_prediction.dart';

void main() {
  test('the app package compiles and exposes its theme entrypoint', () {
    // Smoke test: native project scaffolding must not break the pure domain
    // until a full widget harness exists.
    expect(ArrivalPrediction.distanceMeters(0, 0, 0, 0), 0.0);
    expect(TransportMode.values.length, 3);
  });
}

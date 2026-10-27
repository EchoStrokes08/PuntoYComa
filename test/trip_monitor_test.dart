import 'package:flutter_test/flutter_test.dart';
import 'package:punto_y_coma/domain/entities/trip.dart';
import 'package:punto_y_coma/domain/services/trip_monitor.dart';
import 'package:punto_y_coma/domain/services/wake_up_policy.dart';

void main() {
  const trip = Trip(
    id: 'trip-1',
    destination: GeoPoint(4.65, -74.06),
    mode: TransportMode.metro,
    status: TripStatus.armed,
    alertLeadTime: Duration(minutes: 4),
  );

  test('requests a preventive alert when offline estimate has expired', () {
    final assessment = const TripMonitor().assess(
      currentPosition: const GeoPoint(4.645, -74.06, accuracyMeters: 20),
      trip: trip,
      speedMetersPerSecond: 12,
      sinceLastReliableFix: const Duration(minutes: 4),
      acknowledgementReceived: false,
    );

    expect(assessment.needsPreventiveAlert, isTrue);
    expect(assessment.wakeUpStage, isNot(WakeUpStage.monitoring));
  });
}

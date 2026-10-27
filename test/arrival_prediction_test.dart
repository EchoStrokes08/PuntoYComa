import 'package:flutter_test/flutter_test.dart';
import 'package:punto_y_coma/domain/services/arrival_prediction.dart';
import 'package:punto_y_coma/domain/services/wake_up_policy.dart';

void main() {
  group('ArrivalPrediction', () {
    test('increases the alert radius for a faster vehicle', () {
      const lead = Duration(minutes: 4);
      final slow = ArrivalPrediction.dynamicAlertRadius(
        speedMetersPerSecond: 8,
        leadTime: lead,
        locationAccuracyMeters: 15,
      );
      final fast = ArrivalPrediction.dynamicAlertRadius(
        speedMetersPerSecond: 22,
        leadTime: lead,
        locationAccuracyMeters: 15,
      );
      expect(fast, greaterThan(slow));
    });

    test('dead reckoning expires after three minutes', () {
      final estimate = ArrivalPrediction.extrapolate(
        lastDistanceMeters: 1000,
        speedMetersPerSecond: 10,
        sinceLastFix: const Duration(minutes: 4),
      );
      expect(estimate.valid, isFalse);
      expect(estimate.remainingMeters, 0);
    });
  });

  test('missing acknowledgement escalates before the destination', () {
    expect(
      WakeUpPolicy.evaluate(
        remainingMeters: 70,
        alertRadiusMeters: 500,
        uncertaintyMeters: 10,
        acknowledgementReceived: false,
      ),
      WakeUpStage.persistentHaptic,
    );
  });
}

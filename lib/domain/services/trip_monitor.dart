import '../entities/trip.dart';
import 'arrival_prediction.dart';
import 'wake_up_policy.dart';

/// Orchestrates a trip update. Platform adapters feed it clean location samples.
class TripMonitor {
  const TripMonitor();

  TripAssessment assess({
    required GeoPoint currentPosition,
    required Trip trip,
    required double speedMetersPerSecond,
    required Duration sinceLastReliableFix,
    required bool acknowledgementReceived,
    double trafficMultiplier = 1,
  }) {
    final gpsDistance = ArrivalPrediction.distanceMeters(
      currentPosition.latitude,
      currentPosition.longitude,
      trip.destination.latitude,
      trip.destination.longitude,
    );
    final fallback = ArrivalPrediction.extrapolate(
      lastDistanceMeters: gpsDistance,
      speedMetersPerSecond: speedMetersPerSecond,
      sinceLastFix: sinceLastReliableFix,
    );
    final radius = ArrivalPrediction.dynamicAlertRadius(
      speedMetersPerSecond: speedMetersPerSecond,
      leadTime: trip.alertLeadTime,
      locationAccuracyMeters: currentPosition.accuracyMeters,
      trafficMultiplier: trafficMultiplier,
    );
    final stage = WakeUpPolicy.evaluate(
      remainingMeters: fallback.valid ? fallback.remainingMeters : gpsDistance,
      alertRadiusMeters: radius,
      uncertaintyMeters: fallback.uncertaintyMeters,
      acknowledgementReceived: acknowledgementReceived,
    );
    return TripAssessment(
      distanceMeters: gpsDistance,
      alertRadiusMeters: radius,
      confidence: fallback.valid
          ? TripConfidence.degraded
          : TripConfidence.limited,
      wakeUpStage: stage,
      needsPreventiveAlert: !fallback.valid,
    );
  }
}

enum TripConfidence { high, degraded, limited }

class TripAssessment {
  const TripAssessment({
    required this.distanceMeters,
    required this.alertRadiusMeters,
    required this.confidence,
    required this.wakeUpStage,
    required this.needsPreventiveAlert,
  });

  final double distanceMeters;
  final double alertRadiusMeters;
  final TripConfidence confidence;
  final WakeUpStage wakeUpStage;
  final bool needsPreventiveAlert;
}

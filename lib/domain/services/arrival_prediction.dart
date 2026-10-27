import 'dart:math' as math;

/// Pure business logic; independent from GPS, maps and platform APIs.
class ArrivalPrediction {
  static const _earthRadiusMeters = 6371000.0;

  static double distanceMeters(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    final dLat = _radians(lat2 - lat1);
    final dLng = _radians(lng2 - lng1);
    final a =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(_radians(lat1)) *
            math.cos(_radians(lat2)) *
            math.pow(math.sin(dLng / 2), 2);
    return _earthRadiusMeters * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  /// Radius includes time-to-prepare plus accuracy and conservative braking buffer.
  static double dynamicAlertRadius({
    required double speedMetersPerSecond,
    required Duration leadTime,
    required double locationAccuracyMeters,
    double trafficMultiplier = 1,
  }) {
    final effectiveSpeed =
        speedMetersPerSecond.clamp(2.0, 45.0).toDouble() * trafficMultiplier;
    final travelDistance = effectiveSpeed * leadTime.inSeconds;
    return (travelDistance + locationAccuracyMeters * 2 + 80)
        .clamp(250.0, 5000.0)
        .toDouble();
  }

  /// Dead reckoning is only a short-lived fallback. Its uncertainty grows fast.
  static DeadReckoningEstimate extrapolate({
    required double lastDistanceMeters,
    required double speedMetersPerSecond,
    required Duration sinceLastFix,
  }) {
    final seconds = sinceLastFix.inSeconds.clamp(0, 180).toDouble();
    final distanceTravelled =
        speedMetersPerSecond.clamp(0, 45).toDouble() * seconds;
    return DeadReckoningEstimate(
      remainingMeters: math.max(0, lastDistanceMeters - distanceTravelled),
      uncertaintyMeters:
          30 + (seconds * math.max(1, speedMetersPerSecond) * .35),
      valid: sinceLastFix <= const Duration(minutes: 3),
    );
  }

  static double _radians(double degrees) => degrees * math.pi / 180;
}

class DeadReckoningEstimate {
  const DeadReckoningEstimate({
    required this.remainingMeters,
    required this.uncertaintyMeters,
    required this.valid,
  });
  final double remainingMeters;
  final double uncertaintyMeters;
  final bool valid;
}

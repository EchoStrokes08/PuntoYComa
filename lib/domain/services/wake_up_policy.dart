enum WakeUpStage { monitoring, gentleHaptic, persistentHaptic, audibleFallback }

class WakeUpPolicy {
  /// Never silently drops the alarm: uncertainty advances escalation, not delays it.
  static WakeUpStage evaluate({
    required double remainingMeters,
    required double alertRadiusMeters,
    required double uncertaintyMeters,
    required bool acknowledgementReceived,
  }) {
    if (remainingMeters > alertRadiusMeters + uncertaintyMeters) {
      return WakeUpStage.monitoring;
    }
    if (remainingMeters > alertRadiusMeters * .45) {
      return WakeUpStage.gentleHaptic;
    }
    if (!acknowledgementReceived || remainingMeters > 80) {
      return WakeUpStage.persistentHaptic;
    }
    return WakeUpStage.audibleFallback;
  }
}

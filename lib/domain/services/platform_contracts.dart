import '../entities/trip.dart';
import 'wake_up_actuator_contracts.dart';
import 'wake_up_policy.dart';

/// Native implementations own the battery, permission and background details.
abstract interface class LocationSource {
  Stream<LocationSample> watch(LocationTrackingProfile profile);
}

enum LocationTrackingProfile { passive, balanced, highAccuracy }

class LocationSample {
  const LocationSample({
    required this.position,
    required this.speedMetersPerSecond,
    required this.capturedAt,
  });

  final GeoPoint position;
  final double speedMetersPerSecond;
  final DateTime capturedAt;
}

abstract interface class WakeUpActuator {
  Future<void> setStage(WakeUpStage stage);
  Future<void> showPreventiveSignalLossAlert();
  Future<void> clear();
  /// Reproduce un patrón háptico de prueba una sola vez (sin iniciar alarma).
  Future<void> testPattern(WakeUpStage stage);
  /// Muestra una notificación de prueba para validar sonido y vibración.
  Future<void> testNotification({bool playSound = false});
  /// Registra el manejador de las acciones de la notificación
  /// ("Ya desperté" / "Posponer"). Pasar `null` lo desregistra.
  void onAction(void Function(WakeUpAction action)? handler);
}

abstract interface class TripRepository {
  Future<void> saveActive(Trip trip);
  Future<Trip?> readActive();
  Future<void> clearActive();
}

import '../entities/trip.dart';
import 'wake_up_actuator_contracts.dart';
import 'wake_up_policy.dart';

/// Native implementations own the battery, permission and background details.
abstract interface class LocationSource {
  Stream<LocationSample> watch(LocationTrackingProfile profile);

  /// Pide el permiso de ubicación en contexto (y de notificaciones el
  /// actuador, aparte). Devuelve `true` si el permiso quedó concedido.
  /// Nunca lanza: sin permiso la alarma degrada, no se rompe.
  Future<bool> ensurePermission({bool requestIfDenied});

  /// Consulta el estado del permiso sin pedirlo. Nunca lanza: si la
  /// plataforma no responde, se informa como denegado reversible.
  Future<LocationPermissionStatus> checkPermission();
}

/// Estado del permiso de ubicación visto desde el dominio, sin acoplarse al
/// paquete de geolocalización.
enum LocationPermissionStatus { granted, denied, deniedForever }

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
  /// Configura el comportamiento de la alarma (p. ej. "Sonido al final").
  void configure({required bool soundAtEnd});

  /// Solicita permiso de notificaciones (Android 13+ / iOS). Devuelve
  /// `true` si quedó concedido; nunca lanza.
  Future<bool> requestPermissions();

  /// Registra el manejador de las acciones de la notificación
  /// ("Ya desperté" / "Posponer"). Pasar `null` lo desregistra.
  void onAction(void Function(WakeUpAction action)? handler);
}

abstract interface class TripRepository {
  Future<void> saveActive(Trip trip);
  Future<Trip?> readActive();
  Future<void> clearActive();
}

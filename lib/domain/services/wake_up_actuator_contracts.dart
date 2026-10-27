import 'wake_up_policy.dart';

/// Acción elegida por el usuario desde una notificación de alarma.
enum WakeUpAction { acknowledge, snooze }

/// Extensión del contrato de actuador para pruebas de patrón háptico y
/// notificaciones de alarma. Separado para que la UI pueda probar el actuador
/// sin iniciar una vigilancia completa.
abstract class WakeUpActuatorTester {
  /// Reproduce el patrón háptico de [stage] una sola vez para que el usuario
  /// pueda comprobarlo antes de armar la alarma.
  Future<void> testPattern(WakeUpStage stage);

  /// Muestra una notificación de prueba con el sonido configurado (o sin él).
  Future<void> testNotification({bool playSound = false});
}

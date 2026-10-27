/// Reglas puras del posponer (snooze). Mantenerlas fuera de la UI garantiza
/// que el límite de pospones y la reprogramación se comporten igual en la
/// pantalla, la notificación y las pruebas.
class SnoozePolicy {
  const SnoozePolicy({
    this.maxSnoozes = 3,
    this.defaultSnooze = const Duration(minutes: 1),
    this.options = const [
      Duration(minutes: 1),
      Duration(minutes: 3),
      Duration(minutes: 5),
    ],
  });

  /// Número máximo de pospones por alarma. Evita que el usuario apague la
  /// alarma para siempre con toques repetidos.
  final int maxSnoozes;

  /// Duración usada cuando la acción viene de la notificación (sin elección).
  final Duration defaultSnooze;

  /// Duraciones ofrecidas en la pantalla de alarma.
  final List<Duration> options;

  bool canSnooze(int used) => used < maxSnoozes;

  int remaining(int used) => (maxSnoozes - used).clamp(0, maxSnoozes);

  /// Normaliza una duración pedida por la UI o por la notificación.
  Duration sanitize(Duration? requested) {
    if (requested == null || requested <= Duration.zero) {
      return defaultSnooze;
    }
    return requested;
  }
}

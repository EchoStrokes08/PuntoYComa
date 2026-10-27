/// Texto que se muestra en la notificación persistente del viaje (pantalla
/// de bloqueo / panel de notificaciones). El dominio decide el contenido y
/// el adaptador nativo solo lo pinta.
class TripProgress {
  const TripProgress({
    required this.title,
    required this.body,
    this.alarmActive = false,
    this.percent,
  });

  final String title;
  final String body;
  final bool alarmActive;

  /// Avance del viaje de 0 a 100, o `null` cuando todavía no hay referencia
  /// suficiente (por ejemplo, antes del primer fix).
  final int? percent;

  /// Firma estable para evitar inundar el canal nativo con actualizaciones
  /// idénticas.
  String get signature => '$title|$body|$alarmActive|$percent';
}

/// Contrato de salida para el progreso del viaje. La implementación nativa
/// actualiza la notificación ongoing; en web/desktop no hace nada.
abstract interface class TripProgressSink {
  Future<void> update(TripProgress progress);

  Future<void> clear();
}

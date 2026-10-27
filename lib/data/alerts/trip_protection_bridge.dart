import 'package:flutter/services.dart';

/// Bridges Dart's controller to Android's native foreground service so the
/// armed trip cannot be reaped while the screen is off. It also feeds the
/// ongoing notification with live progress (lock screen / notification shade).
/// Fails open silently on other platforms and in tests (MissingPluginException).
class TripProtectionBridge {
  const TripProtectionBridge();

  static const _channel = MethodChannel('punto_y_coma/protection');

  Future<void> setProtected(bool active) async {
    try {
      // The boot receiver reads this plain-prefs flag; write it first so a
      // reboot between both calls cannot start a service without a trip.
      await _channel.invokeMethod('setArmedFlag', {'armed': active});
      if (active) {
        await _channel.invokeMethod('startForeground');
      } else {
        await _channel.invokeMethod('stopForeground');
      }
    } on MissingPluginException {
      // Web/desktop/test: no native protection available.
    } on PlatformException {
      // Service control failures must not break arming the alarm.
    }
  }

  /// Actualiza el texto visible en la notificación persistente sin abrir la
  /// app. [progress] va de 0 a 1; `null` oculta la barra.
  Future<void> updateProgress({
    required String title,
    required String body,
    int? percent,
  }) async {
    try {
      await _channel.invokeMethod('updateProgress', {
        'title': title,
        'body': body,
        'progress': percent,
      });
    } on MissingPluginException {
      // Sin servicio nativo: la UI sigue mostrando el progreso.
    } on PlatformException {
      // Una notificación desactualizada nunca debe romper la alarma.
    }
  }

  Future<void> clearProgress() async {
    try {
      await _channel.invokeMethod('clearProgress');
    } on MissingPluginException {
      // No-op en plataformas sin servicio.
    } on PlatformException {
      // No-op.
    }
  }
}

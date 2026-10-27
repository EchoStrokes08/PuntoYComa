import 'package:flutter/material.dart';

/// Paleta de colores diseñada a mano para PuntoYcoma.
///
/// Colores semánticos y no genéricos. La paleta evita el aspecto
/// "template de Flutter" usando tonos profundos, cálidos y con carácter.
class PuntoColors {
  PuntoColors._();

  // ── Primario ──────────────────────────────────────────────────────────
  /// Verde bosque profundo: confianza, calma, naturaleza, tránsito seguro.
  static const Color primary = Color(0xFF0F3D2E);
  static const Color primaryContainer = Color(0xFFD8F3DC);
  static const Color primaryFixed = Color(0xFFBFE8C9);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // ── Superficie ────────────────────────────────────────────────────────
  /// Crema cálido: calidez, descanso, noche tranquila.
  static const Color surface = Color(0xFFFCFBF7);
  static const Color surfaceContainer = Color(0xFFF5F2EA);
  static const Color surfaceContainerHigh = Color(0xFFEDE9DA);
  static const Color surfaceContainerHighest = Color(0xFFE4DFD0);

  // ── Fondo ─────────────────────────────────────────────────────────────
  static const Color background = Color(0xFFFCFBF7);

  // ── Borde ─────────────────────────────────────────────────────────────
  static const Color outline = Color(0xFFD1CDC0);
  static const Color outlineVariant = Color(0xFFE7E3D8);

  // ── Texto ─────────────────────────────────────────────────────────────
  static const Color onSurface = Color(0xFF1C1B19);
  static const Color onSurfaceVariant = Color(0xFF494541);
  static const Color onSurfaceLow = Color(0xFF79746E);

  // ── Acento de alarma ──────────────────────────────────────────────────
  /// Naranja quemado: urgencia, atención, despertar. Solo para estados de alarma.
  static const Color alarm = Color(0xFFD9730D);
  static const Color alarmContainer = Color(0xFFFDE8CC);
  static const Color onAlarm = Color(0xFFFFFFFF);

  // ── Señal ─────────────────────────────────────────────────────────────
  static const Color signalGood = Color(0xFF2E7D32);
  static const Color signalDegraded = Color(0xFFF59E0B);
  static const Color signalLimited = Color(0xFFEF4444);

  // ── Éxito ─────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color successContainer = Color(0xFFD1FAE5);

  // ── Sombras ───────────────────────────────────────────────────────────
  static const Color shadow = Color(0x1A000000);
}

/// Tema claro diseñado a mano.
class PuntoLightColors {
  static const Color scaffold = PuntoColors.background;
  static const Color surface = PuntoColors.surface;
  static const Color surfaceContainer = PuntoColors.surfaceContainer;
  static const Color surfaceContainerHigh = PuntoColors.surfaceContainerHigh;
  static const Color surfaceContainerHighest = PuntoColors.surfaceContainerHighest;
  static const Color primary = PuntoColors.primary;
  static const Color primaryContainer = PuntoColors.primaryContainer;
  static const Color onPrimary = PuntoColors.onPrimary;
  static const Color outline = PuntoColors.outline;
  static const Color outlineVariant = PuntoColors.outlineVariant;
  static const Color onSurface = PuntoColors.onSurface;
  static const Color onSurfaceVariant = PuntoColors.onSurfaceVariant;
  static const Color onSurfaceLow = PuntoColors.onSurfaceLow;
  static const Color alarm = PuntoColors.alarm;
  static const Color alarmContainer = PuntoColors.alarmContainer;
  static const Color onAlarm = PuntoColors.onAlarm;
  static const Color signalGood = PuntoColors.signalGood;
  static const Color signalDegraded = PuntoColors.signalDegraded;
  static const Color signalLimited = PuntoColors.signalLimited;
  static const Color success = PuntoColors.success;
  static const Color successContainer = PuntoColors.successContainer;
}

/// Tema oscuro diseñado a mano (no es solo inversión de colores).
class PuntoDarkColors {
  static const Color scaffold = Color(0xFF121512);
  static const Color surface = Color(0xFF1A1D19);
  static const Color surfaceContainer = Color(0xFF212620);
  static const Color surfaceContainerHigh = Color(0xFF2B3229);
  static const Color surfaceContainerHighest = Color(0xFF363E33);
  static const Color primary = Color(0xFF8FD8A8);
  static const Color primaryContainer = Color(0xFF1B4A33);
  static const Color onPrimary = Color(0xFF001B0E);
  static const Color outline = Color(0xFF3F443E);
  static const Color outlineVariant = Color(0xFF2C302A);
  static const Color onSurface = Color(0xFFF2EFE9);
  static const Color onSurfaceVariant = Color(0xFFC9C4B7);
  static const Color onSurfaceLow = Color(0xFF8E8880);
  static const Color alarm = Color(0xFFF5A623);
  static const Color alarmContainer = Color(0xFF3A1E00);
  static const Color onAlarm = Color(0xFFFFFFFF);
  static const Color signalGood = Color(0xFF4ADE80);
  static const Color signalDegraded = Color(0xFFFBBF24);
  static const Color signalLimited = Color(0xFFF87171);
  static const Color success = Color(0xFF34D399);
  static const Color successContainer = Color(0xFF064E3B);
}

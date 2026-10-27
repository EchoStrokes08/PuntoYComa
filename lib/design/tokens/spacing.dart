/// Escala de espaciado de PuntoYcoma.
///
/// Sistema basado en un grid de 8dp. Todos los espaciados de la app
/// deben usar estos valores para mantener consistencia y ritmo visual.
class PuntoSpacing {
  PuntoSpacing._();

  static const double xs = 4.0;   // 4dp  - ajustes mínimos
  static const double sm = 8.0;   // 8dp  - espacio entre elementos relacionados
  static const double md = 16.0;  // 16dp - espacio entre secciones
  static const double lg = 24.0;  // 24dp - espacio entre bloques principales
  static const double xl = 32.0;  // 32dp - espacio entre secciones grandes
  static const double xxl = 48.0; // 48dp - espacio entre secciones con margen amplio

  /// Padding estándar de pantalla (usa lg).
  static const double pagePadding = lg;

  /// Padding compacto (usa md).
  static const double compactPadding = md;

  /// Espacio entre elementos de una lista (usa sm).
  static const double listItemGap = sm;

  /// Espacio entre tarjetas (usa md).
  static const double cardGap = md;
}

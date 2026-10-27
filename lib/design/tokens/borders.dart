import 'package:flutter/material.dart';

/// Sistema de bordes y radios de PuntoYcoma.
class PuntoBorders {
  PuntoBorders._();

  /// Radio pequeño para botones y chips.
  static const double sm = 12.0;

  /// Radio mediano para tarjetas y contenedores.
  static const double md = 20.0;

  /// Radio grande para paneles, modales y CTA principal.
  static const double lg = 28.0;

  /// Radio muy grande para elementos circulares grandes.
  static const double xl = 40.0;

  /// Radio de campos de entrada (búsqueda, formularios).
  static const double input = 16.0;

  /// Radio circular completo.
  static const double circle = double.infinity;

  /// Borde estándar (1.5dp, color outline).
  static const BorderSide standard = BorderSide(
    color: Color(0xFFD1CDC0),
    width: 1.5,
  );

  /// Borde suave (1dp, color outlineVariant).
  static const BorderSide soft = BorderSide(
    color: Color(0xFFE7E3D8),
    width: 1.0,
  );

  /// Borde de alarma (2dp, color alarm).
  static const BorderSide alarm = BorderSide(
    color: Color(0xFFD9730D),
    width: 2.0,
  );

  /// Radio de borde para tarjetas estándar.
  static BorderRadius cardRadius([double? radius]) =>
      BorderRadius.circular(radius ?? md);

  /// Radio de borde para botones estándar.
  static BorderRadius buttonRadius([double? radius]) =>
      BorderRadius.circular(radius ?? sm);

  /// Radio de borde para contenedores grandes.
  static BorderRadius panelRadius([double? radius]) =>
      BorderRadius.circular(radius ?? lg);
}

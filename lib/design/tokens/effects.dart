import 'package:flutter/material.dart';

import 'borders.dart';

/// Sistema de sombras y efectos de PuntoYcoma.
///
/// Sombras suaves y difusas que no ensucian la interfaz. Evita sombras
/// pesadas que hacen que la app se vea barata.
class PuntoEffects {
  PuntoEffects._();

  static const Color shadowColor = Color(0x1A000000);

  /// Sombra sutil para tarjetas elevadas.
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  /// Sombra muy sutil para contenedores flotantes.
  static const List<BoxShadow> soft = [
    BoxShadow(
      color: Color(0x05000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  /// Sombra para elementos de alarma (más visible, sin ser agresiva).
  static const List<BoxShadow> alarm = [
    BoxShadow(
      color: Color(0x2A000000),
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
  ];

  /// Decoración de tarjeta estándar.
  static BoxDecoration cardDecoration({
    Color? color,
    BorderRadius? borderRadius,
    Border? border,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: borderRadius ?? PuntoBorders.cardRadius(),
      border: border,
      boxShadow: card,
    );
  }
}

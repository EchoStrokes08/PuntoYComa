import 'package:flutter/material.dart';

/// Sistema tipográfico de PuntoYcoma.
///
/// Combina una fuente editorial serif para títulos (calma, elegancia, confianza)
/// con una fuente sans-serif neutra para el cuerpo (legibilidad, neutralidad).
/// Evita el aspecto genérico de Flutter al usar tipografía con carácter.
class PuntoTypography {
  PuntoTypography._();

  // ── Familias tipográficas ─────────────────────────────────────────────
  static const String fontFamilySerif = 'PlayfairDisplay';
  static const String fontFamilySans = 'Inter';

  // ── Display ───────────────────────────────────────────────────────────
  /// Títulos principales de pantalla (onboarding, bienvenida).
  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamilySerif,
    fontSize: 48,
    fontWeight: FontWeight.w600,
    height: 1.1,
    letterSpacing: -0.5,
  );

  /// Títulos secundarios grandes.
  static const TextStyle displayMedium = TextStyle(
    fontFamily: fontFamilySerif,
    fontSize: 40,
    fontWeight: FontWeight.w600,
    height: 1.12,
    letterSpacing: -0.4,
  );

  /// Títulos secundarios pequeños.
  static const TextStyle displaySmall = TextStyle(
    fontFamily: fontFamilySerif,
    fontSize: 32,
    fontWeight: FontWeight.w600,
    height: 1.14,
    letterSpacing: -0.3,
  );

  // ── Headline ──────────────────────────────────────────────────────────
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: fontFamilySerif,
    fontSize: 32,
    fontWeight: FontWeight.w600,
    height: 1.16,
    letterSpacing: -0.2,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontFamilySerif,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.18,
    letterSpacing: -0.1,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: fontFamilySerif,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  // ── Title ─────────────────────────────────────────────────────────────
  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamilySans,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.25,
    letterSpacing: 0,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamilySans,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0.1,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: fontFamilySans,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.35,
    letterSpacing: 0.1,
  );

  // ── Body ──────────────────────────────────────────────────────────────
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamilySans,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.2,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamilySans,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.2,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamilySans,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.45,
    letterSpacing: 0.3,
  );

  // ── Label ─────────────────────────────────────────────────────────────
  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamilySans,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0.1,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamilySans,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.35,
    letterSpacing: 0.2,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamilySans,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0.3,
  );

  // ── Caption ───────────────────────────────────────────────────────────
  static const TextStyle captionLarge = TextStyle(
    fontFamily: fontFamilySans,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: 0.3,
  );

  static const TextStyle captionMedium = TextStyle(
    fontFamily: fontFamilySans,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: 0.3,
  );

  static const TextStyle captionSmall = TextStyle(
    fontFamily: fontFamilySans,
    fontSize: 10,
    fontWeight: FontWeight.w400,
    height: 1.35,
    letterSpacing: 0.4,
  );
}

/// Extensión para aplicar estilos de PuntoTypography a TextStyle.
extension PuntoTextStyle on TextStyle {
  TextStyle get serif => copyWith(fontFamily: PuntoTypography.fontFamilySerif);
  TextStyle get sans => copyWith(fontFamily: PuntoTypography.fontFamilySans);
}

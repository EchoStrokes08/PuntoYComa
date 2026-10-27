import 'package:flutter/material.dart';

import '../tokens/tokens.dart';

/// Tema de PuntoYcoma diseñado a mano.
///
/// Define los temas claro y oscuro usando la paleta de colores, tipografía
/// y espaciado del sistema de diseño. Evita el aspecto genérico de
/// Material 3 por defecto usando colores semánticos con carácter.
class PuntoTheme {
  PuntoTheme._();

  /// Tema claro.
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: PuntoLightColors.surface,
      colorScheme: const ColorScheme.light(
        surface: PuntoLightColors.surface,
        surfaceContainer: PuntoLightColors.surfaceContainer,
        primary: PuntoLightColors.primary,
        primaryContainer: PuntoLightColors.primaryContainer,
        onPrimary: PuntoLightColors.onPrimary,
        outline: PuntoLightColors.outline,
        outlineVariant: PuntoLightColors.outlineVariant,
        onSurface: PuntoLightColors.onSurface,
        onSurfaceVariant: PuntoLightColors.onSurfaceVariant,
        error: PuntoColors.signalLimited,
        errorContainer: PuntoColors.alarmContainer,
        onError: PuntoColors.onAlarm,
      ),
      textTheme: _textTheme(PuntoLightColors.onSurface, PuntoLightColors.onSurfaceVariant),
      cardTheme: CardThemeData(
        elevation: 0,
        color: PuntoLightColors.surfaceContainer,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: PuntoBorders.cardRadius(),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: PuntoLightColors.primary,
          foregroundColor: PuntoLightColors.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: PuntoBorders.buttonRadius(),
          ),
          textStyle: PuntoTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: PuntoLightColors.primary,
          side: PuntoBorders.standard,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: PuntoBorders.buttonRadius(),
          ),
          textStyle: PuntoTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: PuntoLightColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: PuntoBorders.buttonRadius(PuntoSpacing.sm),
          ),
          textStyle: PuntoTypography.labelMedium.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: PuntoLightColors.surfaceContainerHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PuntoBorders.input),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PuntoBorders.input),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PuntoBorders.input),
          borderSide: const BorderSide(
            color: PuntoLightColors.primary,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        hintStyle: PuntoTypography.bodyMedium.copyWith(
          color: PuntoLightColors.onSurfaceLow,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: PuntoLightColors.primary,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return PuntoLightColors.primary;
          }
          return PuntoLightColors.outlineVariant;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return PuntoColors.primaryContainer;
          }
          return PuntoLightColors.outlineVariant;
        }),
      ),
      dividerTheme: const DividerThemeData(
        color: PuntoColors.outlineVariant,
        thickness: 1,
        space: 1,
      ),
    );
  }

  /// Tema oscuro diseñado a mano (no inversión de colores).
  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: PuntoDarkColors.surface,
      colorScheme: const ColorScheme.dark(
        surface: PuntoDarkColors.surface,
        surfaceContainer: PuntoDarkColors.surfaceContainer,
        primary: PuntoDarkColors.primary,
        primaryContainer: PuntoDarkColors.primaryContainer,
        onPrimary: PuntoDarkColors.onPrimary,
        outline: PuntoDarkColors.outline,
        outlineVariant: PuntoDarkColors.outlineVariant,
        onSurface: PuntoDarkColors.onSurface,
        onSurfaceVariant: PuntoDarkColors.onSurfaceVariant,
        error: PuntoColors.signalLimited,
        errorContainer: PuntoColors.alarmContainer,
        onError: PuntoDarkColors.onAlarm,
      ),
      textTheme: _textTheme(PuntoDarkColors.onSurface, PuntoDarkColors.onSurfaceVariant),
      cardTheme: CardThemeData(
        elevation: 0,
        color: PuntoDarkColors.surfaceContainer,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: PuntoBorders.cardRadius(),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: PuntoDarkColors.primary,
          foregroundColor: PuntoDarkColors.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: PuntoBorders.buttonRadius(),
          ),
          textStyle: PuntoTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: PuntoDarkColors.primary,
          side: const BorderSide(
            color: PuntoDarkColors.outline,
            width: 1.5,
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: PuntoBorders.buttonRadius(),
          ),
          textStyle: PuntoTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: PuntoDarkColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: PuntoBorders.buttonRadius(PuntoSpacing.sm),
          ),
          textStyle: PuntoTypography.labelMedium.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: PuntoDarkColors.surfaceContainerHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PuntoBorders.input),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PuntoBorders.input),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PuntoBorders.input),
          borderSide: const BorderSide(
            color: PuntoDarkColors.primary,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        hintStyle: PuntoTypography.bodyMedium.copyWith(
          color: PuntoDarkColors.onSurfaceLow,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: PuntoDarkColors.primary,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return PuntoDarkColors.primary;
          }
          return PuntoDarkColors.outlineVariant;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return PuntoDarkColors.primaryContainer;
          }
          return PuntoDarkColors.outlineVariant;
        }),
      ),
      dividerTheme: const DividerThemeData(
        color: PuntoDarkColors.outlineVariant,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static TextTheme _textTheme(Color onSurface, Color onSurfaceVariant) {
    return TextTheme(
      displayLarge: PuntoTypography.displayLarge.copyWith(color: onSurface),
      displayMedium: PuntoTypography.displayMedium.copyWith(color: onSurface),
      displaySmall: PuntoTypography.displaySmall.copyWith(color: onSurface),
      headlineLarge: PuntoTypography.headlineLarge.copyWith(color: onSurface),
      headlineMedium: PuntoTypography.headlineMedium.copyWith(color: onSurface),
      headlineSmall: PuntoTypography.headlineSmall.copyWith(color: onSurface),
      titleLarge: PuntoTypography.titleLarge.copyWith(color: onSurface),
      titleMedium: PuntoTypography.titleMedium.copyWith(color: onSurface),
      titleSmall: PuntoTypography.titleSmall.copyWith(color: onSurface),
      bodyLarge: PuntoTypography.bodyLarge.copyWith(color: onSurface),
      bodyMedium: PuntoTypography.bodyMedium.copyWith(color: onSurfaceVariant),
      bodySmall: PuntoTypography.bodySmall.copyWith(color: onSurfaceVariant),
      labelLarge: PuntoTypography.labelLarge.copyWith(color: onSurface),
      labelMedium: PuntoTypography.labelMedium.copyWith(color: onSurfaceVariant),
      labelSmall: PuntoTypography.labelSmall.copyWith(color: onSurfaceVariant),
    );
  }
}

/// Helper para acceder a colores del tema actual.
extension PuntoColorScheme on BuildContext {
  Color get primary => Theme.of(this).colorScheme.primary;
  Color get onPrimary => Theme.of(this).colorScheme.onPrimary;
  Color get surface => Theme.of(this).colorScheme.surface;
  Color get surfaceContainer => Theme.of(this).colorScheme.surfaceContainer;
  Color get surfaceContainerHighest =>
      Theme.of(this).colorScheme.surfaceContainerHighest;
  Color get outlineVariant => Theme.of(this).colorScheme.outlineVariant;
  /// Tarjeta elevada (blanca en claro, verde-gris en oscuro).
  Color get surfaceBright => Theme.of(this).brightness == Brightness.dark
      ? PuntoDarkColors.surfaceBright
      : PuntoLightColors.surfaceBright;
  Color get primaryContainer => Theme.of(this).colorScheme.primaryContainer;
  Color get onSurface => Theme.of(this).colorScheme.onSurface;
  Color get onSurfaceVariant => Theme.of(this).colorScheme.onSurfaceVariant;
  Color get onSurfaceLow => Theme.of(this).colorScheme.onSurfaceVariant;
  Color get outline => Theme.of(this).colorScheme.outline;
  Color get error => Theme.of(this).colorScheme.error;

  /// Tinta oscura sobre contenedores primarios claros (≥ 4.5:1).
  Color get onPrimaryContainer => PuntoColors.onPrimaryContainer;

  /// Naranja quemado de alarma (consciente del tema).
  Color get alarm => Theme.of(this).brightness == Brightness.dark
      ? PuntoDarkColors.alarm
      : PuntoLightColors.alarm;

  /// Contenedor de alarma (consciente del tema).
  Color get alarmContainer => Theme.of(this).brightness == Brightness.dark
      ? PuntoDarkColors.alarmContainer
      : PuntoLightColors.alarmContainer;

  /// Texto/icono sobre el color de alarma.
  Color get onAlarm => PuntoColors.onAlarm;

  /// Verde de éxito (consciente del tema).
  Color get success => Theme.of(this).brightness == Brightness.dark
      ? PuntoDarkColors.success
      : PuntoLightColors.success;

  /// Ámbar de advertencia (consciente del tema).
  Color get warning => Theme.of(this).brightness == Brightness.dark
      ? PuntoDarkColors.signalDegraded
      : PuntoLightColors.signalDegraded;
}

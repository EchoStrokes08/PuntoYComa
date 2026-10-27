import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:punto_y_coma/data/routing/local_stop_cache.dart';
import 'package:punto_y_coma/design/theme/app_theme.dart';
import 'package:punto_y_coma/domain/entities/trip.dart';
import 'package:punto_y_coma/presentation/screens/screens.dart';

import 'helpers/test_fonts.dart';

/// Tests de humo de layout: montan cada pantalla en los tamaños físicos
/// 360×800 y 411×866 y verifican que no se lance ninguna excepción de
/// layout (ni "unbounded height", ni "infinite width", ni overflow).
///
/// Las pantallas se montan con el tema real de la app (PuntoTheme.light) y
/// las fuentes reales de producción (ver [loadAppFonts]).
void main() {
  setUpAll(loadAppFonts);

  const screenSizes = [Size(360, 800), Size(411, 866)];

  /// Monta [screen] a [size] y avanza un poco las animaciones de entrada.
  Future<void> pumpScreen(
    WidgetTester tester,
    Widget screen,
    Size size,
  ) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: PuntoTheme.light(),
        home: screen,
      ),
    );
    // Deja avanzar el revelado escalonado y las transiciones de entrada.
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
  }

  CachedStop sampleStop() => const CachedStop(
        id: 'stop-smoke',
        name: 'Calle 76',
        latitude: 4.6680,
        longitude: -74.0519,
        mode: TransportMode.metro,
        routeId: 'B1',
      );

  Trip sampleTrip() => Trip(
        id: 'trip-smoke',
        destination: const GeoPoint(4.6680, -74.0519, accuracyMeters: 25),
        mode: TransportMode.metro,
        status: TripStatus.alarmed,
        alertLeadTime: const Duration(minutes: 4),
      );

  for (final size in screenSizes) {
    group('pantallas a ${size.width}x${size.height}', () {
      testWidgets('WelcomeScreen se monta sin excepciones de layout',
          (tester) async {
        await pumpScreen(tester, const WelcomeScreen(), size);
      });

      testWidgets('DestinationScreen se monta sin excepciones de layout',
          (tester) async {
        await pumpScreen(tester, const DestinationScreen(), size);
      });

      testWidgets('PreparationScreen se monta sin excepciones de layout',
          (tester) async {
        await pumpScreen(tester, PreparationScreen(stop: sampleStop()), size);
      });

      testWidgets('ArmedTripScreen se monta sin excepciones de layout',
          (tester) async {
        await pumpScreen(tester, const ArmedTripScreen(), size);
      });

      testWidgets('AlarmWakeScreen se monta sin excepciones de layout',
          (tester) async {
        await pumpScreen(tester, AlarmWakeScreen(trip: sampleTrip()), size);
      });

      testWidgets('HistoryScreen se monta sin excepciones de layout',
          (tester) async {
        await pumpScreen(tester, const HistoryScreen(), size);
      });

      testWidgets('SettingsScreen se monta sin excepciones de layout',
          (tester) async {
        await pumpScreen(tester, const SettingsScreen(), size);
      });
    });
  }

  testWidgets('WelcomeScreen en modo oscuro se monta sin excepciones',
      (tester) async {
    tester.view.physicalSize = const Size(411, 866);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: PuntoTheme.light(),
        darkTheme: PuntoTheme.dark(),
        themeMode: ThemeMode.dark,
        home: const WelcomeScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
  });
}

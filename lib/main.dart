import 'dart:async';

import 'package:flutter/material.dart';

import 'data/alerts/local_notification_wake_up_actuator.dart';
import 'data/alerts/trip_protection_bridge.dart';
import 'data/location/geolocator_location_source.dart';
import 'data/persistence/secure_trip_repository.dart';
import 'data/persistence/trip_history_repository.dart';
import 'data/routing/local_stop_cache.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/state/trip_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Data layer adapters ──────────────────────────────────────────────
  final locationSource = GeolocatorLocationSource();
  final actuator = LocalNotificationWakeUpActuator();
  final tripRepository = SecureTripRepository();
  final tripHistoryRepository = TripHistoryRepositoryImpl();
  final stopCache = LocalStopCache();

  // ── Presentation layer ───────────────────────────────────────────────
  final controller = TripController(
    locationSource: locationSource,
    tripRepository: tripRepository,
    tripHistoryRepository: tripHistoryRepository,
    wakeUpActuator: actuator,
    requestPermission: locationSource.ensurePermission,
    setForegroundProtection: TripProtectionBridge().setProtected,
    stopCache: stopCache,
  );

  // A reboot must not orphan armed alarms within the documented OS limits.
  unawaited(controller.tryResume());

  runApp(
    PuntoYComaApp(
      controller: controller,
      onSoundConfigured: (sound) => actuator.configure(soundAtEnd: sound),
    ),
  );
}

class PuntoYComaApp extends StatelessWidget {
  const PuntoYComaApp({
    super.key,
    required this.controller,
    required this.onSoundConfigured,
  });

  final TripController controller;
  final ValueChanged<bool> onSoundConfigured;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'PuntoYcoma',
    debugShowCheckedModeBanner: false,
    theme: _theme(Brightness.light),
    darkTheme: _theme(Brightness.dark),
    themeMode: ThemeMode.system,
    home: HomeScreen(controller: controller, onSoundConfigured: onSoundConfigured),
  );

  ThemeData _theme(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xff176B57),
      brightness: brightness,
      contrastLevel: 0.2,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: brightness == Brightness.dark
          ? const Color(0xff101514)
          : const Color(0xffFCFBF7),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}

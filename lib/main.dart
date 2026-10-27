import 'package:flutter/material.dart';

import 'data/alerts/local_notification_wake_up_actuator.dart';
import 'data/alerts/trip_protection_bridge.dart';
import 'data/location/geolocator_location_source.dart';
import 'data/persistence/secure_trip_repository.dart';
import 'data/persistence/trip_history_repository.dart';
import 'data/routing/local_stop_cache.dart';
import 'design/theme/app_theme.dart';
import 'presentation/app_router.dart';
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
  controller.tryResume();

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
  Widget build(BuildContext context) => MaterialApp.router(
    routerConfig: AppRouter.createRouter(),
    title: 'PuntoYcoma',
    debugShowCheckedModeBanner: false,
    theme: PuntoTheme.light(),
    darkTheme: PuntoTheme.dark(),
    themeMode: ThemeMode.system,
  );
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:punto_y_coma/data/persistence/in_memory_secure_storage.dart';
import 'package:punto_y_coma/data/routing/local_stop_cache.dart';
import 'package:punto_y_coma/design/theme/app_theme.dart';
import 'package:punto_y_coma/domain/entities/trip.dart';
import 'package:punto_y_coma/domain/services/platform_contracts.dart';
import 'package:punto_y_coma/domain/services/trip_history_contracts.dart';
import 'package:punto_y_coma/domain/services/wake_up_actuator_contracts.dart';
import 'package:punto_y_coma/domain/services/wake_up_policy.dart';
import 'package:punto_y_coma/presentation/app_router.dart';
import 'package:punto_y_coma/presentation/state/punto_scope.dart';
import 'package:punto_y_coma/presentation/state/trip_controller.dart';

import 'test_fonts.dart';

// ── Falsos de la capa de plataforma (sin plugins nativos) ────────────────

/// Emite fixes de ubicación manualmente y recuerda el último perfil pedido.
///
/// El stream es asíncrono (`sync: false`): un stream síncrono deja
/// pendiente la baja de la suscripción dentro de la zona FakeAsync de
/// `testWidgets` (solo se drena en `pump`), lo que colgaba
/// `controller.cancel()/finish()` en las pruebas de pantalla.
class FakeLocationSource implements LocationSource {
  final controller = StreamController<LocationSample>.broadcast();
  LocationTrackingProfile? lastProfile;
  bool permissionGranted = true;
  int permissionRequests = 0;

  /// Estado que reporta `checkPermission` cuando el permiso está negado.
  LocationPermissionStatus deniedStatus = LocationPermissionStatus.denied;

  @override
  Stream<LocationSample> watch(LocationTrackingProfile profile) {
    lastProfile = profile;
    return controller.stream;
  }

  @override
  Future<bool> ensurePermission({bool requestIfDenied = true}) async {
    permissionRequests++;
    return permissionGranted;
  }

  @override
  Future<LocationPermissionStatus> checkPermission() async =>
      permissionGranted
          ? LocationPermissionStatus.granted
          : deniedStatus;

  void emit(LocationSample sample) => controller.add(sample);

  Future<void> close() async {
    await controller.close();
  }
}

/// Persistencia falsa del viaje armado.
class FakeTripRepository implements TripRepository {
  Trip? stored;
  int saved = 0;
  int cleared = 0;

  @override
  Future<void> saveActive(Trip trip) async {
    stored = trip;
    saved++;
  }

  @override
  Future<Trip?> readActive() async => stored;

  @override
  Future<void> clearActive() async {
    stored = null;
    cleared++;
  }
}

/// Historial falso (recientes + favoritos) en memoria.
class FakeTripHistoryRepository implements TripHistoryRepository {
  final List<Trip> recents = [];
  final Set<String> favorites = {};

  @override
  Future<void> saveRecent(Trip trip) async => recents.add(trip);

  @override
  Future<List<Trip>> getRecents({int limit = 10}) async =>
      recents.reversed.take(limit).toList();

  @override
  Future<void> toggleFavorite(String tripId) async {
    if (favorites.contains(tripId)) {
      favorites.remove(tripId);
    } else {
      favorites.add(tripId);
    }
  }

  @override
  Future<List<Trip>> getFavorites() async =>
      recents.where((t) => favorites.contains(t.id)).toList();

  @override
  Future<bool> isFavorite(String tripId) async => favorites.contains(tripId);

  @override
  Future<void> clearRecents() async => recents.clear();
}

/// Actuador falso: registra cada llamada de la alarma sin tocar plugins.
class FakeWakeUpActuator implements WakeUpActuator {
  final stages = <WakeUpStage>[];
  int preventiveAlerts = 0;
  int clears = 0;
  int testPatterns = 0;
  int testNotifications = 0;
  int permissionRequests = 0;
  void Function(WakeUpAction action)? actionHandler;

  @override
  void configure({required bool soundAtEnd}) {}

  @override
  Future<bool> requestPermissions() async {
    permissionRequests++;
    return true;
  }

  @override
  void onAction(void Function(WakeUpAction action)? handler) =>
      actionHandler = handler;

  @override
  Future<void> setStage(WakeUpStage stage) async => stages.add(stage);

  @override
  Future<void> showPreventiveSignalLossAlert() async => preventiveAlerts++;

  @override
  Future<void> clear() async => clears++;

  @override
  Future<void> testPattern(WakeUpStage stage) async {
    testPatterns++;
    stages.add(stage);
  }

  @override
  Future<void> testNotification({bool playSound = false}) async {
    testNotifications++;
  }
}

// ── Ensamblaje de la app real con dependencias falsas ────────────────────

/// Conjunto de dependencias para probar la app completa (pantallas reales +
/// enrutador real + controlador real) sin tocar plugins nativos.
///
/// El reloj es controlable para el posponer y el temporizador manual.
class TestBundle {
  TestBundle({bool seedStops = false}) {
    locationSource = FakeLocationSource();
    tripRepository = FakeTripRepository();
    historyRepository = FakeTripHistoryRepository();
    actuator = FakeWakeUpActuator();

    clockValue = DateTime(2026, 10, 27, 7);
    if (seedStops) {
      stopCache = LocalStopCache(storage: InMemorySecureStorage());
    } else {
      stopCache = null;
    }

    router = AppRouter.createRouter();
    app = _TestRoot(bundle: this);

    controller = TripController(
      locationSource: locationSource,
      tripRepository: tripRepository,
      tripHistoryRepository: historyRepository,
      wakeUpActuator: actuator,
      requestPermission: () async => locationSource.permissionGranted,
      setForegroundProtection: (_) async {},
      reassessmentInterval: const Duration(hours: 1),
      clock: () => clockValue,
      stopCache: stopCache,
    );
  }

  late final FakeLocationSource locationSource;
  late final FakeTripRepository tripRepository;
  late final FakeTripHistoryRepository historyRepository;
  late final FakeWakeUpActuator actuator;
  late final TripController controller;
  late final LocalStopCache? stopCache;
  late final GoRouter router;
  late final Widget app;

  DateTime clockValue = DateTime(2026, 10, 27, 7);

  /// Siembra el caché de paradas recientes (solo con `seedStops: true`).
  ///
  /// Debe llamarse antes de [pumpApp] para que `loadRecents()` del view model
  /// encuentre las paradas al montar la pantalla de destino.
  Future<void> seedStops() async {
    await stopCache!.saveStopsForRoute('recientes', [
      sampleStop(id: 'stop-1', name: 'Calle 76'),
      sampleStop(id: 'stop-2', name: 'Calle 72'),
    ]);
  }

  void dispose() => controller.dispose();
}

class _TestRoot extends StatelessWidget {
  const _TestRoot({required this.bundle});

  final TestBundle bundle;

  @override
  Widget build(BuildContext context) {
    return PuntoScope(
      controller: bundle.controller,
      actuator: bundle.actuator,
      locationSource: bundle.locationSource,
      historyRepository: bundle.historyRepository,
      child: MaterialApp.router(
        routerConfig: bundle.router,
        title: 'PuntoYcoma',
        debugShowCheckedModeBanner: false,
        theme: PuntoTheme.light(),
        darkTheme: PuntoTheme.dark(),
        themeMode: ThemeMode.light,
      ),
    );
  }
}

// ── Datos de ejemplo ──────────────────────────────────────────────────────

const kDestination = GeoPoint(4.6680, -74.0519, accuracyMeters: 25);

CachedStop sampleStop({String id = 'stop-1', String name = 'Calle 76'}) =>
    CachedStop(
      id: id,
      name: name,
      latitude: 4.6680,
      longitude: -74.0519,
      mode: TransportMode.metro,
      routeId: 'B1',
    );

Trip draftedTrip([Duration lead = const Duration(minutes: 4)]) => Trip(
      id: 'trip-e2e',
      destination: kDestination,
      mode: TransportMode.metro,
      status: TripStatus.draft,
      alertLeadTime: lead,
    );

/// Fix de ubicación a [meters] al norte del destino.
LocationSample fixAtMetersNorth(double meters, {DateTime? at}) =>
    LocationSample(
      position: GeoPoint(
        kDestination.latitude + meters / 111320,
        kDestination.longitude,
        accuracyMeters: 10,
      ),
      speedMetersPerSecond: 6,
      capturedAt: at ?? DateTime.now(),
    );

/// Siembra las paradas recientes en el caché en memoria.
Future<void> seedRecentStops(TestBundle bundle) async {
  await bundle.stopCache!.saveStopsForRoute('recientes', [
    sampleStop(id: 'stop-1', name: 'Calle 76'),
    sampleStop(id: 'stop-2', name: 'Calle 72'),
  ]);
}

/// Avanza el enrutador tras `router.go(...)`: una sola pump solo programa el
/// frame y la transición de página dura 250 ms, así que hacen falta bombes
/// repetidos hasta que la pantalla destino terminó de construirse.
Future<void> pumpRoute(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

/// Cancela el viaje armado al final de una prueba.
///
/// `await controller.cancel()` se cuelga en el entorno de pruebas de widgets:
/// la zona FakeAsync de `testWidgets` solo drena sus microtareas dentro de
/// `pump`, y la cancelación espera la baja de una suscripción del stream
/// falso. Se invoca sin `await` y se bombear una vez para que la zona
/// procese la cancelación; los temporizadores del controlador se detienen de
/// todos modos de forma síncrona al iniciar `cancel()`.
Future<void> cancelTrip(WidgetTester tester, TestBundle bundle) async {
  unawaited(bundle.controller.cancel());
  await tester.pump();
}

/// Monta la app con las fuentes reales en un viewport de teléfono.
Future<void> pumpApp(
  WidgetTester tester,
  TestBundle bundle, {
  Size size = const Size(411, 866),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await loadAppFonts();
  await tester.pumpWidget(bundle.app);
  await tester.pump(const Duration(milliseconds: 350));
}

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:punto_y_coma/domain/entities/trip.dart';
import 'package:punto_y_coma/domain/services/platform_contracts.dart';
import 'package:punto_y_coma/domain/services/trip_history_contracts.dart';
import 'package:punto_y_coma/domain/services/trip_monitor.dart';
import 'package:punto_y_coma/domain/services/wake_up_policy.dart';
import 'package:punto_y_coma/presentation/state/trip_controller.dart';

class _FakeLocationSource implements LocationSource {
  final controller = StreamController<LocationSample>.broadcast(sync: true);
  LocationTrackingProfile? lastProfile;

  @override
  Stream<LocationSample> watch(LocationTrackingProfile profile) {
    lastProfile = profile;
    return controller.stream;
  }

  void emit(LocationSample sample) => controller.add(sample);

  Future<void> close() => controller.close();
}

class _FakeTripRepository implements TripRepository {
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

class _FakeTripHistoryRepository implements TripHistoryRepository {
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

class _FakeActuator implements WakeUpActuator {
  final stages = <WakeUpStage>[];
  int preventiveAlerts = 0;
  int cleared = 0;
  int testPatterns = 0;
  int testNotifications = 0;

  @override
  Future<void> setStage(WakeUpStage stage) async => stages.add(stage);

  @override
  Future<void> showPreventiveSignalLossAlert() async => preventiveAlerts++;

  @override
  Future<void> clear() async => cleared++;

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

DateTime _clockValue = DateTime(2026, 10, 25, 7);

void main() {
  const destination = GeoPoint(4.6680, -74.0519, accuracyMeters: 0);

  late _FakeLocationSource locationSource;
  late _FakeTripRepository repository;
  late _FakeTripHistoryRepository historyRepository;
  late _FakeActuator actuator;

  setUp(() {
    locationSource = _FakeLocationSource();
    repository = _FakeTripRepository();
    historyRepository = _FakeTripHistoryRepository();
    actuator = _FakeActuator();
    _clockValue = DateTime(2026, 10, 25, 7);
  });

  TripController buildController({bool permissionGranted = true}) =>
      TripController(
        locationSource: locationSource,
        tripRepository: repository,
        tripHistoryRepository: historyRepository,
        wakeUpActuator: actuator,
        requestPermission: () async => permissionGranted,
        reassessmentInterval: const Duration(milliseconds: 10),
        clock: () => _clockValue,
      );

  LocationSample sampleAtMetersNorth(double meters) => LocationSample(
        position: GeoPoint(
          destination.latitude + meters / 111320,
          destination.longitude,
          accuracyMeters: 10,
        ),
        speedMetersPerSecond: 2,
        capturedAt: _clockValue,
      );

  Trip draft() => Trip(
        id: 'trip-1',
        destination: destination,
        mode: TransportMode.metro,
        status: TripStatus.draft,
        alertLeadTime: const Duration(minutes: 3),
      );

  test('arming requests permission, persists and starts monitoring', () async {
    final controller = buildController();
    final armed = await controller.arm(draft());
    expect(armed, isTrue);
    expect(repository.saved, 1);
    expect(repository.stored?.status, TripStatus.armed);
    expect(locationSource.lastProfile, LocationTrackingProfile.balanced);
    await controller.cancel();
    expect(repository.cleared, 1);
    expect(actuator.cleared, 1);
  });

  test('denied permission keeps the trip unarmed', () async {
    final controller = buildController(permissionGranted: false);
    final armed = await controller.arm(draft());
    expect(armed, isFalse);
    expect(controller.issue, TripIssue.permissionDenied);
    expect(repository.saved, 0);
  });

  test('a first stable fix far away only monitors', () async {
    final controller = buildController();
    await controller.arm(draft());
    locationSource.emit(sampleAtMetersNorth(2000));
    expect(controller.wakeUpStage, WakeUpStage.monitoring);
    expect(controller.assessment?.confidence, TripConfidence.degraded);
  });

  test('entering the alert radius escalates even without acknowledgement',
      () async {
    final controller = buildController();
    await controller.arm(draft());
    locationSource.emit(sampleAtMetersNorth(2000));
    // 300 m: inside radius (450 m) but above 45 %: gentle vibration.
    locationSource.emit(sampleAtMetersNorth(300));
    expect(controller.wakeUpStage, WakeUpStage.gentleHaptic);
    // 100 m past half radius and unacknowledged: insistence advances.
    locationSource.emit(sampleAtMetersNorth(100));
    expect(controller.wakeUpStage, WakeUpStage.persistentHaptic);
    expect(actuator.stages, contains(WakeUpStage.persistentHaptic));
  });

  test('acknowledgement with a nearby fix reaches the audible fallback',
      () async {
    final controller = buildController();
    await controller.arm(draft());
    locationSource.emit(sampleAtMetersNorth(100));
    controller.acknowledgeAlarm();
    locationSource.emit(sampleAtMetersNorth(50));
    expect(controller.wakeUpStage, WakeUpStage.audibleFallback);
  });

  test('four minutes without fixes fire exactly one preventive alert',
      () async {
    final controller = buildController();
    await controller.arm(draft());
    locationSource.emit(sampleAtMetersNorth(2000));
    // Emits settle synchronously (sync broadcast stream).
    _clockValue = _clockValue.add(const Duration(minutes: 4));
    // The periodic reassessment timer keeps uncertainty growing.
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(actuator.preventiveAlerts, 1);
    expect(controller.assessment?.needsPreventiveAlert, isTrue);
  });

  test('a reliable low-precision fix is ignored, a clean one is kept',
      () async {
    final controller = buildController();
    await controller.arm(draft());
    locationSource.emit(LocationSample(
      position: GeoPoint(
        destination.latitude + 0.02,
        destination.longitude,
        accuracyMeters: 200,
      ),
      speedMetersPerSecond: 2,
      capturedAt: _clockValue,
    ));
    expect(controller.assessment, isNull);
    locationSource.emit(sampleAtMetersNorth(2000));
    expect(controller.assessment, isNotNull);
  });

  test('an armed trip survives an app restart', () async {
    final first = buildController();
    await first.arm(draft());
    await first.cancel();
    repository.stored = Trip(
      id: 'trip-1',
      destination: destination,
      mode: TransportMode.metro,
      status: TripStatus.armed,
      alertLeadTime: const Duration(minutes: 3),
    );
    final second = buildController();
    expect(await second.tryResume(), isTrue);
    expect(second.isArmed, isTrue);
    expect(second.activeTrip?.id, 'trip-1');
  });

  test('tryResume returns false when nothing is armed', () async {
    final controller = buildController();
    expect(await controller.tryResume(), isFalse);
  });

  // ── Fase 3: perfiles dinámicos de ubicación ──────────────────────────

  test('starts with balanced profile when arming', () async {
    final controller = buildController();
    await controller.arm(draft());
    expect(controller.currentProfile, LocationTrackingProfile.balanced);
    await controller.cancel();
  });

  test('switches to passive profile when far from destination', () async {
    final controller = buildController();
    await controller.arm(draft());
    locationSource.emit(sampleAtMetersNorth(4000));
    await Future<void>.delayed(Duration.zero);
    expect(controller.currentProfile, LocationTrackingProfile.passive);
    await controller.cancel();
  });

  test('switches to balanced profile at mid distance', () async {
    final controller = buildController();
    await controller.arm(draft());
    locationSource.emit(sampleAtMetersNorth(2000));
    await Future<void>.delayed(Duration.zero);
    expect(controller.currentProfile, LocationTrackingProfile.balanced);
    await controller.cancel();
  });

  test('switches to high accuracy when near destination', () async {
    final controller = buildController();
    await controller.arm(draft());
    locationSource.emit(sampleAtMetersNorth(500));
    await Future<void>.delayed(Duration.zero);
    expect(controller.currentProfile, LocationTrackingProfile.highAccuracy);
    await controller.cancel();
  });

  test('switches to high accuracy when alarm stage is active', () async {
    final controller = buildController();
    await controller.arm(draft());
    locationSource.emit(sampleAtMetersNorth(100));
    await Future<void>.delayed(Duration.zero);
    expect(controller.currentProfile, LocationTrackingProfile.highAccuracy);
    await controller.cancel();
  });

  test('profile resets to balanced after cancel', () async {
    final controller = buildController();
    await controller.arm(draft());
    locationSource.emit(sampleAtMetersNorth(500));
    await Future<void>.delayed(Duration.zero);
    expect(controller.currentProfile, LocationTrackingProfile.highAccuracy);
    await controller.cancel();
    expect(controller.currentProfile, LocationTrackingProfile.balanced);
  });

  // ── Fase 3: filtro de saltos imposibles ──────────────────────────────

  test('discards impossible speed jumps between consecutive fixes', () async {
    final controller = buildController();
    await controller.arm(draft());
    // Primer fix válido a 2000 m del destino.
    locationSource.emit(sampleAtMetersNorth(2000));
    await Future<void>.delayed(Duration.zero);
    expect(controller.wakeUpStage, WakeUpStage.monitoring);

    // Avanzar 1 segundo y emitir un fix a ~111 km (1 grado de latitud):
    // velocidad implicada ≈ 111 km/s, imposible para bus/metro.
    _clockValue = _clockValue.add(const Duration(seconds: 1));
    locationSource.emit(LocationSample(
      position: GeoPoint(
        destination.latitude + 1.0,
        destination.longitude,
        accuracyMeters: 10,
      ),
      speedMetersPerSecond: 0,
      capturedAt: _clockValue,
    ));
    await Future<void>.delayed(Duration.zero);

    // El salto imposible se descarta: la evaluación sigue en monitoring.
    expect(controller.wakeUpStage, WakeUpStage.monitoring);
    await controller.cancel();
  });

  test('accepts reasonable speed jumps between consecutive fixes', () async {
    final controller = buildController();
    await controller.arm(draft());
    locationSource.emit(sampleAtMetersNorth(2000));
    await Future<void>.delayed(Duration.zero);
    expect(controller.wakeUpStage, WakeUpStage.monitoring);

    // Avanzar 10 segundos y mover 100 m (10 m/s ≈ 36 km/h, razonable).
    _clockValue = _clockValue.add(const Duration(seconds: 10));
    locationSource.emit(sampleAtMetersNorth(1900));
    await Future<void>.delayed(Duration.zero);

    expect(controller.assessment, isNotNull);
    await controller.cancel();
  });

  test('low precision fix is still ignored even if speed is reasonable', () async {
    final controller = buildController();
    await controller.arm(draft());
    locationSource.emit(LocationSample(
      position: GeoPoint(
        destination.latitude + 0.02,
        destination.longitude,
        accuracyMeters: 200,
      ),
      speedMetersPerSecond: 2,
      capturedAt: _clockValue,
    ));
    expect(controller.assessment, isNull);
    await controller.cancel();
  });
}

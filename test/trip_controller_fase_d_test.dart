import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:punto_y_coma/domain/entities/trip.dart';
import 'package:punto_y_coma/domain/services/platform_contracts.dart';
import 'package:punto_y_coma/domain/services/trip_history_contracts.dart';
import 'package:punto_y_coma/domain/services/trip_progress_contracts.dart';
import 'package:punto_y_coma/domain/services/wake_up_actuator_contracts.dart';
import 'package:punto_y_coma/domain/services/wake_up_policy.dart';
import 'package:punto_y_coma/presentation/state/trip_controller.dart';

/// Fase D: posponer, edición del viaje armado, temporizador manual, acciones
/// de la notificación y progreso persistente.

class _FakeLocationSource implements LocationSource {
  final controller = StreamController<LocationSample>.broadcast(sync: true);

  @override
  Stream<LocationSample> watch(LocationTrackingProfile profile) =>
      controller.stream;

  void emit(LocationSample sample) => controller.add(sample);
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
    if (!favorites.remove(tripId)) favorites.add(tripId);
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
  int cleared = 0;
  void Function(WakeUpAction action)? actionHandler;

  @override
  void onAction(void Function(WakeUpAction action)? handler) =>
      actionHandler = handler;

  @override
  Future<void> setStage(WakeUpStage stage) async => stages.add(stage);

  @override
  Future<void> showPreventiveSignalLossAlert() async {}

  @override
  Future<void> clear() async => cleared++;

  @override
  Future<void> testPattern(WakeUpStage stage) async {}

  @override
  Future<void> testNotification({bool playSound = false}) async {}
}

class _RecordingProgressSink implements TripProgressSink {
  final updates = <TripProgress>[];
  int clears = 0;

  TripProgress get last => updates.last;

  @override
  Future<void> update(TripProgress progress) async => updates.add(progress);

  @override
  Future<void> clear() async => clears++;
}

DateTime _clockValue = DateTime(2026, 10, 25, 7);

void main() {
  const destination = GeoPoint(4.6680, -74.0519);

  late _FakeLocationSource locationSource;
  late _FakeTripRepository repository;
  late _FakeTripHistoryRepository historyRepository;
  late _FakeActuator actuator;
  late _RecordingProgressSink progressSink;

  setUp(() {
    locationSource = _FakeLocationSource();
    repository = _FakeTripRepository();
    historyRepository = _FakeTripHistoryRepository();
    actuator = _FakeActuator();
    progressSink = _RecordingProgressSink();
    _clockValue = DateTime(2026, 10, 25, 7);
  });

  TripController buildController() => TripController(
        locationSource: locationSource,
        tripRepository: repository,
        tripHistoryRepository: historyRepository,
        wakeUpActuator: actuator,
        requestPermission: () async => true,
        reassessmentInterval: const Duration(hours: 1),
        clock: () => _clockValue,
        progressSink: progressSink,
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

  Trip draft() => const Trip(
        id: 'trip-1',
        destination: destination,
        mode: TransportMode.metro,
        status: TripStatus.draft,
        alertLeadTime: Duration(minutes: 3),
      );

  /// Deja correr los temporizadores reales y las continuaciones pendientes.
  Future<void> settle([int milliseconds = 120]) =>
      Future<void>.delayed(Duration(milliseconds: milliseconds));

  test('posponer silencia la alarma y la vuelve a disparar', () async {
    final controller = buildController();
    await controller.arm(draft());
    locationSource.emit(sampleAtMetersNorth(100));
    expect(controller.wakeUpStage, WakeUpStage.persistentHaptic);
    final stagesBeforeSnooze = actuator.stages.length;

    await controller.snooze(duration: const Duration(milliseconds: 40));
    expect(controller.isSnoozed, isTrue);
    expect(controller.snoozeCount, 1);
    expect(controller.wakeUpStage, WakeUpStage.monitoring);
    expect(actuator.cleared, greaterThan(0));

    await settle();
    expect(controller.isSnoozed, isFalse);
    expect(controller.wakeUpStage, WakeUpStage.persistentHaptic);
    expect(actuator.stages.length, greaterThan(stagesBeforeSnooze));

    await controller.cancel();
  });

  test('el posponer se limita a tres veces por alarma', () async {
    final controller = buildController();
    await controller.arm(draft());

    for (var i = 0; i < 3; i++) {
      await controller.snooze(duration: const Duration(minutes: 5));
    }
    expect(controller.snoozeCount, 3);
    expect(controller.canSnooze, isFalse);

    await controller.snooze(duration: const Duration(minutes: 5));
    expect(controller.snoozeCount, 3);

    await controller.cancel();
  });

  test('confirmar despierto reinicia el presupuesto de pospones', () async {
    final controller = buildController();
    await controller.arm(draft());
    locationSource.emit(sampleAtMetersNorth(100));

    await controller.snooze(duration: const Duration(minutes: 5));
    expect(controller.snoozeCount, 1);

    controller.acknowledgeAlarm();
    expect(controller.isSnoozed, isFalse);
    expect(controller.snoozeCount, 0);

    await controller.cancel();
  });

  test('editar el viaje armado persiste sin cancelar la vigilancia', () async {
    final controller = buildController();
    await controller.arm(draft());

    final edited = await controller.editActiveTrip(
      destination: const GeoPoint(4.7000, -74.0500),
      alertLeadTime: const Duration(minutes: 8),
    );

    expect(edited, isTrue);
    expect(controller.isArmed, isTrue);
    expect(controller.activeTrip?.alertLeadTime, const Duration(minutes: 8));
    expect(controller.activeTrip?.destination.latitude, 4.7000);
    expect(repository.saved, 2);
    expect(repository.cleared, 0);
    expect(repository.stored?.destination.latitude, 4.7000);

    await controller.cancel();
  });

  test('el temporizador manual suena aunque no haya GPS', () async {
    final controller = buildController();
    await controller.arm(draft());

    await controller.startManualTimer(const Duration(milliseconds: 40));
    expect(controller.isManualArmed, isTrue);
    expect(controller.wakeUpStage, WakeUpStage.monitoring);

    await settle();
    expect(controller.isManualAlarmActive, isTrue);
    expect(controller.wakeUpStage, WakeUpStage.audibleFallback);
    expect(actuator.stages, contains(WakeUpStage.audibleFallback));

    await controller.cancel();
  });

  test('cancelar el temporizador manual devuelve el control al GPS', () async {
    final controller = buildController();
    await controller.arm(draft());
    await controller.startManualTimer(const Duration(minutes: 10));
    expect(controller.isManualArmed, isTrue);

    controller.cancelManualTimer();
    expect(controller.isManualArmed, isFalse);
    expect(controller.isManualAlarmActive, isFalse);

    await controller.cancel();
  });

  test('la acción Posponer de la notificación reprograma la alarma', () async {
    final controller = buildController();
    await controller.arm(draft());
    locationSource.emit(sampleAtMetersNorth(100));

    actuator.actionHandler!(WakeUpAction.snooze);
    await settle(20);

    expect(controller.isSnoozed, isTrue);
    expect(controller.snoozeCount, 1);

    await controller.cancel();
  });

  test('la acción Ya desperté de la notificación cierra el viaje', () async {
    final controller = buildController();
    await controller.arm(draft());
    locationSource.emit(sampleAtMetersNorth(100));

    actuator.actionHandler!(WakeUpAction.acknowledge);
    await settle(20);

    expect(controller.isArmed, isFalse);
    expect(repository.cleared, 1);
    expect(historyRepository.recents.single.status, TripStatus.completed);
  });

  test('la notificación persistente refleja el avance y se limpia', () async {
    final controller = buildController();
    await controller.arm(draft());
    expect(progressSink.updates, isNotEmpty);

    locationSource.emit(sampleAtMetersNorth(2000));
    await settle(10);
    expect(progressSink.last.percent, 0);
    expect(progressSink.last.body, contains('km'));

    _clockValue = _clockValue.add(const Duration(minutes: 1));
    locationSource.emit(sampleAtMetersNorth(1200));
    await settle(10);

    expect(progressSink.last.percent, inInclusiveRange(1, 99));
    expect(progressSink.last.body, contains('1.2 km'));

    await controller.cancel();
    await settle(10);
    expect(progressSink.clears, 1);
  });
}

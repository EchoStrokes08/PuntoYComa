import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/routing/local_stop_cache.dart';

import '../../domain/entities/trip.dart';
import '../../domain/services/arrival_prediction.dart';
import '../../domain/services/platform_contracts.dart';
import '../../domain/services/snooze_policy.dart';
import '../../domain/services/trip_history_contracts.dart';
import '../../domain/services/trip_monitor.dart';
import '../../domain/services/trip_progress_contracts.dart';
import '../../domain/services/wake_up_actuator_contracts.dart';
import '../../domain/services/wake_up_policy.dart';

/// Why an alarm could not be armed or keep running.
enum TripIssue { permissionDenied, locationUnavailable, none }

/// Presentation-level state machine: it feeds clean samples into the pure
/// `TripMonitor`, persists the armed trip and drives the `WakeUpActuator`.
/// Battery/permission specifics live in the `data` layer implementations.
///
/// Fase D añade tres capacidades que comparten el mismo estado:
/// - posponer (snooze) con límite y reprogramación real;
/// - edición del viaje armado sin cancelar la vigilancia;
/// - temporizador manual como último recurso cuando el GPS no responde.
class TripController extends ChangeNotifier {
  TripController({
    required LocationSource locationSource,
    required TripRepository tripRepository,
    required TripHistoryRepository tripHistoryRepository,
    required WakeUpActuator wakeUpActuator,
    Future<bool> Function()? requestPermission,
    Duration reassessmentInterval = const Duration(seconds: 3),
    DateTime Function()? clock,
    Future<void> Function(bool)? setForegroundProtection,
    LocalStopCache? stopCache,
    TripProgressSink? progressSink,
    SnoozePolicy snoozePolicy = const SnoozePolicy(),
  }) : _locationSource = locationSource,
       _tripRepository = tripRepository,
       _tripHistoryRepository = tripHistoryRepository,
       _wakeUpActuator = wakeUpActuator,
       _requestPermission = requestPermission,
       _reassessmentInterval = reassessmentInterval,
       _clock = clock ?? DateTime.now,
       _setForegroundProtection = setForegroundProtection,
       _stopCache = stopCache ?? LocalStopCache(),
       _progressSink = progressSink,
       _snoozePolicy = snoozePolicy {
    _wakeUpActuator.onAction(_handleWakeUpAction);
  }

  final LocationSource _locationSource;
  final TripRepository _tripRepository;
  final TripHistoryRepository _tripHistoryRepository;
  final WakeUpActuator _wakeUpActuator;
  final Future<bool> Function()? _requestPermission;
  final Duration _reassessmentInterval;
  final DateTime Function() _clock;
  final Future<void> Function(bool)? _setForegroundProtection;
  final LocalStopCache _stopCache;
  final TripProgressSink? _progressSink;
  final SnoozePolicy _snoozePolicy;

  static const _maxAcceptableAccuracyMeters = 60.0;

  /// Velocidad implicada máxima aceptada entre dos fixes consecutivos.
  /// 50 m/s ≈ 180 km/h: imposible para bus/metro, por tanto el salto es ruido.
  static const _maxImpliedSpeedMps = 50.0;

  /// Umbrales de distancia para cambiar de perfil de ubicación (ahorro vs precisión).
  static const _farDistanceMeters = 3000.0;
  static const _nearDistanceMeters = 1000.0;

  Trip? _activeTrip;
  TripAssessment? _assessment;
  LocationSample? _lastSample;
  LocationSample? _previousValidSample;
  DateTime? _lastReliableFixAt;
  Timer? _ticker;
  StreamSubscription<LocationSample>? _subscription;
  LocationTrackingProfile _currentProfile = LocationTrackingProfile.balanced;
  TripIssue _issue = TripIssue.none;
  bool _preventiveAlertShown = false;
  bool _acknowledged = false;
  WakeUpStage? _lastStageReported;

  // ── Posponer (snooze) ──────────────────────────────────────────────────
  Timer? _snoozeTimer;
  DateTime? _snoozeUntil;
  int _snoozeCount = 0;
  bool _snoozeRestoresManualAlarm = false;

  // ── Temporizador manual (último recurso) ───────────────────────────────
  Timer? _manualTimer;
  DateTime? _manualDeadline;
  bool _manualFired = false;

  String? _lastProgressSignature;

  /// Distancia al destino en el primer fix del viaje; sirve únicamente para
  /// dibujar la barra de progreso de la notificación persistente.
  double? _armDistanceMeters;

  Trip? get activeTrip => _activeTrip;
  TripAssessment? get assessment => _assessment;
  TripIssue get issue => _issue;
  bool get isArmed => _activeTrip != null;
  LocationTrackingProfile get currentProfile => _currentProfile;
  LocalStopCache get stopCache => _stopCache;
  TripHistoryRepository get tripHistory => _tripHistoryRepository;
  SnoozePolicy get snoozePolicy => _snoozePolicy;

  /// Etapa audible manual: gana sobre la evaluación del GPS.
  WakeUpStage get wakeUpStage {
    if (_manualFired) return WakeUpStage.audibleFallback;
    if (_snoozeUntil != null) return WakeUpStage.monitoring;
    return _assessment?.wakeUpStage ?? WakeUpStage.monitoring;
  }

  // ── Estado de posponer ─────────────────────────────────────────────────

  bool get isSnoozed => _snoozeUntil != null;
  DateTime? get snoozeUntil => _snoozeUntil;
  int get snoozeCount => _snoozeCount;
  bool get canSnooze =>
      isArmed && _snoozePolicy.canSnooze(_snoozeCount);
  int get snoozesRemaining => _snoozePolicy.remaining(_snoozeCount);

  Duration? get snoozeRemaining {
    final until = _snoozeUntil;
    if (until == null) return null;
    final remaining = until.difference(_clock());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  // ── Estado del temporizador manual ─────────────────────────────────────

  bool get isManualArmed => _manualDeadline != null;
  bool get isManualAlarmActive => _manualFired;
  DateTime? get manualDeadline => _manualDeadline;

  Duration? get manualRemaining {
    final deadline = _manualDeadline;
    if (deadline == null) return null;
    final remaining = deadline.difference(_clock());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Arms an already prepared [draft]: asks for permission first, then
  /// persists and starts monitoring. Returns false when denied.
  Future<bool> arm(Trip draft) async {
    final requestPermission = _requestPermission;
    if (requestPermission != null) {
      final granted = await requestPermission();
      if (!granted) {
        _issue = TripIssue.permissionDenied;
        notifyListeners();
        return false;
      }
    }
    final armedTrip = Trip(
      id: draft.id,
      destination: draft.destination,
      mode: draft.mode,
      status: TripStatus.armed,
      alertLeadTime: draft.alertLeadTime,
    );
    _resetRuntimeState();
    _activeTrip = armedTrip;
    _issue = TripIssue.none;
    _currentProfile = LocationTrackingProfile.balanced;
    await _tripRepository.saveActive(armedTrip);
    unawaited(_setForegroundProtection?.call(true));
    _startReassessing();
    _startWatching(LocationTrackingProfile.balanced);
    _pushProgress(force: true);
    notifyListeners();
    return true;
  }

  /// Restores a persisted armed trip after the app was closed.
  Future<bool> tryResume() async {
    final trip = await _tripRepository.readActive();
    if (trip == null || trip.status != TripStatus.armed) return false;
    _resetRuntimeState();
    _activeTrip = trip;
    _currentProfile = LocationTrackingProfile.balanced;
    unawaited(_setForegroundProtection?.call(true));
    _startReassessing();
    _startWatching(LocationTrackingProfile.balanced);
    _pushProgress(force: true);
    notifyListeners();
    return true;
  }

  /// Edita el viaje armado sin cancelarlo: cambia el margen, el destino o el
  /// modo y persiste el cambio cifrado. La vigilancia continúa con el nuevo
  /// objetivo.
  Future<bool> editActiveTrip({
    GeoPoint? destination,
    TransportMode? mode,
    Duration? alertLeadTime,
  }) async {
    final trip = _activeTrip;
    if (trip == null) return false;
    final updated = trip.copyWith(
      destination: destination,
      mode: mode,
      alertLeadTime: alertLeadTime,
    );
    _activeTrip = updated;
    // Un destino nuevo invalida el filtro de saltos relativo a la ruta vieja
    // y reinicia la referencia de la barra de progreso.
    if (destination != null) {
      _previousValidSample = null;
      _armDistanceMeters = null;
    }
    await _tripRepository.saveActive(updated);
    _assess();
    _pushProgress(force: true);
    notifyListeners();
    return true;
  }

  /// Reprograma la alarma sin apagarla. Vuelve a sonar tras [duration]
  /// (1, 3 o 5 minutos en la UI, 1 minuto desde la notificación). El número
  /// de pospones se limita en [SnoozePolicy].
  Future<void> snooze({Duration? duration}) async {
    if (!canSnooze) return;
    final actual = _snoozePolicy.sanitize(duration);
    _snoozeCount++;
    _snoozeUntil = _clock().add(actual);
    _snoozeRestoresManualAlarm = _manualFired;
    _manualFired = false;
    _lastStageReported = WakeUpStage.monitoring;
    _snoozeTimer?.cancel();
    _snoozeTimer = Timer(actual, _finishSnooze);
    await _wakeUpActuator.clear();
    _pushProgress(force: true);
    notifyListeners();
  }

  /// Activa el último recurso: una alarma por tiempo cuando el GPS no es
  /// confiable (túnel, permiso revocado, batería). Convive con la vigilancia
  /// por distancia: gana la que ocurra primero.
  Future<void> startManualTimer(Duration duration) async {
    if (_activeTrip == null) return;
    final actual = duration <= Duration.zero
        ? const Duration(minutes: 10)
        : duration;
    _manualTimer?.cancel();
    _manualDeadline = _clock().add(actual);
    _manualFired = false;
    _manualTimer = Timer(actual, _fireManualAlarm);
    _pushProgress(force: true);
    notifyListeners();
  }

  void cancelManualTimer() {
    _manualTimer?.cancel();
    _manualTimer = null;
    _manualDeadline = null;
    _manualFired = false;
    _lastStageReported = null;
    _pushProgress(force: true);
    _assess();
    notifyListeners();
  }

  /// Called by the rider's UI once they confirm being awake.
  void acknowledgeAlarm() {
    _clearSnooze();
    _clearManualTimer(keepAlarmState: false);
    _acknowledged = true;
    _assess();
  }

  /// Guarda el viaje recién completado en recientes para que el usuario pueda
  /// repetirlo y desarma la vigilancia.
  Future<void> finish() => _stop(TripStatus.completed);

  /// Guarda el just-completed trip to recents so the rider can repeat it.
  Future<void> saveToRecents(Trip trip) async {
    await _tripHistoryRepository.saveRecent(trip);
  }

  /// Toggles the favorite flag on [tripId].
  Future<void> toggleFavorite(String tripId) async {
    await _tripHistoryRepository.toggleFavorite(tripId);
    notifyListeners();
  }

  /// Checks whether [tripId] is marked as favorite.
  Future<bool> isFavorite(String tripId) async =>
      _tripHistoryRepository.isFavorite(tripId);

  /// Returns the favorite trips.
  Future<List<Trip>> getFavorites() async =>
      _tripHistoryRepository.getFavorites();

  /// Returns recent trips (most recent first).
  Future<List<Trip>> getRecents({int limit = 10}) async =>
      _tripHistoryRepository.getRecents(limit: limit);

  Future<void> cancel() => _stop(TripStatus.cancelled);

  Future<void> _stop(TripStatus status) async {
    _ticker?.cancel();
    _ticker = null;
    _clearSnooze();
    _clearManualTimer(keepAlarmState: false);
    unawaited(_subscription?.cancel());
    _subscription = null;
    final closedTrip = _activeTrip;
    _activeTrip = null;
    _assessment = null;
    _lastSample = null;
    _previousValidSample = null;
    _lastReliableFixAt = null;
    _currentProfile = LocationTrackingProfile.balanced;
    _preventiveAlertShown = false;
    _acknowledged = false;
    _lastStageReported = null;
    _lastProgressSignature = null;
    _armDistanceMeters = null;
    await _wakeUpActuator.clear();
    await _tripRepository.clearActive();
    unawaited(_setForegroundProtection?.call(false));
    unawaited(_progressSink?.clear());
    // Persist the closed trip to recents for quick repeat.
    if (closedTrip != null) {
      unawaited(saveToRecents(closedTrip.copyWith(status: status)));
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _snoozeTimer?.cancel();
    _manualTimer?.cancel();
    _subscription?.cancel();
    _wakeUpActuator.onAction(null);
    super.dispose();
  }

  /// Preferred profile while the alarm is on and the stop is still far.
  void requestHighAccuracy() => _startWatching(LocationTrackingProfile.highAccuracy);

  /// Tests a haptic pattern without starting an alarm. Used by the UI to let
  /// the rider preview vibrations before arming.
  Future<void> testVibration(WakeUpStage stage) async =>
      _wakeUpActuator.testPattern(stage);

  /// Tests a notification with optional sound. Used by the UI preview.
  Future<void> testNotification({bool playSound = false}) async =>
      _wakeUpActuator.testNotification(playSound: playSound);

  // ── Internos ───────────────────────────────────────────────────────────

  void _resetRuntimeState() {
    _clearSnooze();
    _clearManualTimer(keepAlarmState: false);
    _acknowledged = false;
    _preventiveAlertShown = false;
    _lastSample = null;
    _previousValidSample = null;
    _lastReliableFixAt = null;
    _assessment = null;
    _lastStageReported = null;
    _lastProgressSignature = null;
    _armDistanceMeters = null;
    _snoozeCount = 0;
  }

  void _finishSnooze() {
    _snoozeUntil = null;
    _snoozeTimer = null;
    if (_snoozeRestoresManualAlarm) {
      _snoozeRestoresManualAlarm = false;
      _fireManualAlarm();
      return;
    }
    _lastStageReported = null;
    _assess();
  }

  void _fireManualAlarm() {
    _manualTimer?.cancel();
    _manualTimer = null;
    _manualDeadline = null;
    if (_snoozeUntil != null) {
      // El usuario pidió posponer: la alarma manual vuelve al terminar.
      _snoozeRestoresManualAlarm = true;
      notifyListeners();
      return;
    }
    _manualFired = true;
    _lastStageReported = WakeUpStage.audibleFallback;
    unawaited(_wakeUpActuator.setStage(WakeUpStage.audibleFallback));
    _pushProgress(force: true);
    notifyListeners();
  }

  void _clearSnooze() {
    _snoozeTimer?.cancel();
    _snoozeTimer = null;
    _snoozeUntil = null;
    _snoozeRestoresManualAlarm = false;
    _snoozeCount = 0;
  }

  void _clearManualTimer({required bool keepAlarmState}) {
    _manualTimer?.cancel();
    _manualTimer = null;
    _manualDeadline = null;
    if (!keepAlarmState) _manualFired = false;
  }

  void _handleWakeUpAction(WakeUpAction action) {
    switch (action) {
      case WakeUpAction.acknowledge:
        unawaited(finish());
      case WakeUpAction.snooze:
        unawaited(snooze());
    }
  }

  void _startWatching(LocationTrackingProfile profile) {
    _subscription?.cancel();
    _subscription = _locationSource.watch(profile).listen(
      _onSample,
      onError: (Object _) {
        _issue = TripIssue.locationUnavailable;
        _pushProgress(force: true);
        notifyListeners();
      },
    );
  }

  void _startReassessing() {
    _ticker?.cancel();
    // Keeps uncertainty growing even when GPS goes silent inside a tunnel.
    _ticker = Timer.periodic(_reassessmentInterval, (_) => _assess());
  }

  void _onSample(LocationSample sample) {
    if (sample.position.accuracyMeters > _maxAcceptableAccuracyMeters) {
      // Low precision fixes announce more noise than signal.
      return;
    }

    // Filtro de saltos imposibles: dos fixes consecutivos no pueden implicar
    /// una velocidad superior a lo que un bus o metro pueden alcanzar.
    if (_previousValidSample != null) {
      final dt = sample.capturedAt.difference(_previousValidSample!.capturedAt);
      if (dt.inSeconds > 0) {
        final dist = ArrivalPrediction.distanceMeters(
          _previousValidSample!.position.latitude,
          _previousValidSample!.position.longitude,
          sample.position.latitude,
          sample.position.longitude,
        );
        final impliedSpeed = dist / dt.inSeconds;
        if (impliedSpeed > _maxImpliedSpeedMps) {
          return; // Salto imposible: descartar este fix.
        }
      }
    }

    _previousValidSample = sample;
    _lastSample = sample;
    _lastReliableFixAt = sample.capturedAt;
    _issue = TripIssue.none;
    _assess();
    _maybeSwitchProfile();
  }

  /// Ajusta el perfil de ubicación según la fase del viaje:
  /// lejos (>= 3 km) → pasivo para ahorrar batería; cerca (<= 1 km) o
  /// en etapa de alarma → alta precisión. Entre medio, balanceado.
  void _maybeSwitchProfile() {
    final assessment = _assessment;
    if (assessment == null) return;

    final desired = switch (assessment.wakeUpStage) {
      WakeUpStage.monitoring => switch (assessment.distanceMeters) {
        > _farDistanceMeters => LocationTrackingProfile.passive,
        > _nearDistanceMeters => LocationTrackingProfile.balanced,
        _ => LocationTrackingProfile.highAccuracy,
      },
      _ => LocationTrackingProfile.highAccuracy,
    };

    if (desired != _currentProfile) {
      _currentProfile = desired;
      // Re-armar el watch con el nuevo perfil fuera del flujo síncrono del
      // listener para no cancelar el stream que estamos procesando.
      unawaited(Future.microtask(() => _startWatching(desired)));
    }
  }

  void _assess() {
    final trip = _activeTrip;
    final sample = _lastSample;
    if (trip == null) return;
    if (sample == null) {
      // No fix yet: never interpret silence as progress.
      _pushProgress(force: true);
      notifyListeners();
      return;
    }
    final sinceLastReliableFix =
        _clock().difference(_lastReliableFixAt ?? sample.capturedAt);
    final assessment = const TripMonitor().assess(
      currentPosition: sample.position,
      trip: trip,
      speedMetersPerSecond: sample.speedMetersPerSecond,
      sinceLastReliableFix: sinceLastReliableFix,
      acknowledgementReceived: _acknowledged,
    );
    _assessment = assessment;
    _armDistanceMeters ??= assessment.remainingMeters;
    if (assessment.needsPreventiveAlert && !_preventiveAlertShown) {
      _preventiveAlertShown = true;
      unawaited(_wakeUpActuator.showPreventiveSignalLossAlert());
    }
    // Durante un pospone o una alarma manual ya disparada no se degrada la
    // etapa: el usuario pidió silencio, no desactivar la alarma.
    if (_snoozeUntil == null && !_manualFired) {
      _escalateTo(assessment.wakeUpStage);
    }
    _pushProgress();
    notifyListeners();
  }

  void _escalateTo(WakeUpStage stage) {
    if (_lastStageReported == stage) return;
    _lastStageReported = stage;
    unawaited(_wakeUpActuator.setStage(stage));
  }

  void _pushProgress({bool force = false}) {
    final sink = _progressSink;
    if (sink == null) return;
    final progress = _buildProgress();
    if (!force && progress.signature == _lastProgressSignature) return;
    _lastProgressSignature = progress.signature;
    unawaited(sink.update(progress));
  }

  TripProgress _buildProgress() {
    final trip = _activeTrip;
    if (trip == null) {
      return const TripProgress(
        title: 'PuntoYcoma',
        body: 'Sin viaje armado.',
      );
    }
    if (_manualFired) {
      return const TripProgress(
        title: 'Tu tiempo terminó',
        body: 'Alarma manual activa. Confirma que despertaste.',
        alarmActive: true,
      );
    }
    final snooze = snoozeRemaining;
    if (snooze != null) {
      final minutes = (snooze.inSeconds / 60).ceil().clamp(1, 99);
      return TripProgress(
        title: 'Alarma pospuesta',
        body: 'Volverá a sonar en $minutes min. Puedes confirmar desde aquí.',
      );
    }
    final current = _assessment;
    if (current == null) {
      return const TripProgress(
        title: 'PuntoYcoma vigila tu viaje',
        body: 'Esperando señal de ubicación…',
      );
    }
    final alarming = current.wakeUpStage != WakeUpStage.monitoring;
    final distance = _formatDistance(current.remainingMeters);
    final eta = _formatEta(current.etaSeconds);
    return TripProgress(
      title: alarming ? 'Tu parada se acerca' : 'PuntoYcoma vigila tu viaje',
      body: alarming
          ? 'A $distance · $eta. Confirma que despertaste.'
          : 'Faltan $distance · $eta para tu parada.',
      alarmActive: alarming,
      percent: _progressPercent(current),
    );
  }

  /// Avance del viaje respecto al primer fix. Sin referencia previa no se
  /// inventa una barra: la notificación muestra solo texto.
  int? _progressPercent(TripAssessment current) {
    final initial = _armDistanceMeters;
    if (initial == null || initial < 200) return null;
    final covered = 1 - current.remainingMeters / initial;
    return (covered * 100).round().clamp(0, 100);
  }

  static String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.round()} m';
  }

  static String _formatEta(int seconds) {
    if (seconds <= 60) return 'menos de 1 min';
    final minutes = (seconds / 60).ceil();
    return '$minutes min';
  }
}

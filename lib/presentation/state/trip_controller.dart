import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/routing/local_stop_cache.dart';

import '../../domain/entities/trip.dart';
import '../../domain/services/arrival_prediction.dart';
import '../../domain/services/platform_contracts.dart';
import '../../domain/services/trip_history_contracts.dart';
import '../../domain/services/trip_monitor.dart';
import '../../domain/services/wake_up_policy.dart';

/// Why an alarm could not be armed or keep running.
enum TripIssue { permissionDenied, locationUnavailable, none }

/// Presentation-level state machine: it feeds clean samples into the pure
/// `TripMonitor`, persists the armed trip and drives the `WakeUpActuator`.
/// Battery/permission specifics live in the `data` layer implementations.
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
  }) : _locationSource = locationSource,
       _tripRepository = tripRepository,
       _tripHistoryRepository = tripHistoryRepository,
       _wakeUpActuator = wakeUpActuator,
       _requestPermission = requestPermission,
       _reassessmentInterval = reassessmentInterval,
       _clock = clock ?? DateTime.now,
       _setForegroundProtection = setForegroundProtection,
       _stopCache = stopCache ?? LocalStopCache();

  final LocationSource _locationSource;
  final TripRepository _tripRepository;
  final TripHistoryRepository _tripHistoryRepository;
  final WakeUpActuator _wakeUpActuator;
  final Future<bool> Function()? _requestPermission;
  final Duration _reassessmentInterval;
  final DateTime Function() _clock;
  final Future<void> Function(bool)? _setForegroundProtection;
  final LocalStopCache _stopCache;

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

  Trip? get activeTrip => _activeTrip;
  TripAssessment? get assessment => _assessment;
  TripIssue get issue => _issue;
  bool get isArmed => _activeTrip != null;
  WakeUpStage get wakeUpStage => _assessment?.wakeUpStage ?? WakeUpStage.monitoring;
  LocationTrackingProfile get currentProfile => _currentProfile;
  LocalStopCache get stopCache => _stopCache;
  TripHistoryRepository get tripHistory => _tripHistoryRepository;

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
    _activeTrip = armedTrip;
    _issue = TripIssue.none;
    _preventiveAlertShown = false;
    _acknowledged = false;
    _lastSample = null;
    _previousValidSample = null;
    _lastReliableFixAt = null;
    _currentProfile = LocationTrackingProfile.balanced;
    await _tripRepository.saveActive(armedTrip);
    unawaited(_setForegroundProtection?.call(true));
    _startReassessing();
    _startWatching(LocationTrackingProfile.balanced);
    notifyListeners();
    return true;
  }

  /// Restores a persisted armed trip after the app was closed.
  Future<bool> tryResume() async {
    final trip = await _tripRepository.readActive();
    if (trip == null || trip.status != TripStatus.armed) return false;
    _activeTrip = trip;
    _previousValidSample = null;
    _currentProfile = LocationTrackingProfile.balanced;
    unawaited(_setForegroundProtection?.call(true));
    _startReassessing();
    _startWatching(LocationTrackingProfile.balanced);
    notifyListeners();
    return true;
  }

  /// Called by the rider's UI once they confirm being awake.
  void acknowledgeAlarm() {
    _acknowledged = true;
    _assess();
  }

  /// Saves the just-completed trip to recents so the rider can repeat it.
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

  Future<void> cancel() async {
    _ticker?.cancel();
    _ticker = null;
    await _subscription?.cancel();
    _subscription = null;
    final completedTrip = _activeTrip;
    _activeTrip = null;
    _assessment = null;
    _lastSample = null;
    _previousValidSample = null;
    _lastReliableFixAt = null;
    _currentProfile = LocationTrackingProfile.balanced;
    _preventiveAlertShown = false;
    _acknowledged = false;
    await _wakeUpActuator.clear();
    await _tripRepository.clearActive();
    unawaited(_setForegroundProtection?.call(false));
    // Persist the completed trip to recents for quick repeat.
    if (completedTrip != null) {
      unawaited(saveToRecents(completedTrip));
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _subscription?.cancel();
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

  void _startWatching(LocationTrackingProfile profile) {
    _subscription?.cancel();
    _subscription = _locationSource.watch(profile).listen(
      _onSample,
      onError: (Object _) {
        _issue = TripIssue.locationUnavailable;
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
    if (assessment.needsPreventiveAlert && !_preventiveAlertShown) {
      _preventiveAlertShown = true;
      unawaited(_wakeUpActuator.showPreventiveSignalLossAlert());
    }
    _escalateTo(assessment.wakeUpStage);
    notifyListeners();
  }

  void _escalateTo(WakeUpStage stage) {
    if (_lastStageReported == stage) return;
    _lastStageReported = stage;
    unawaited(_wakeUpActuator.setStage(stage));
  }
}

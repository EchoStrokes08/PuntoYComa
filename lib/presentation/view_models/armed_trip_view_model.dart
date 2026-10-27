import 'package:flutter/foundation.dart';

import '../../domain/entities/trip.dart';
import '../../domain/services/platform_contracts.dart';
import '../../domain/services/trip_monitor.dart';
import '../../domain/services/wake_up_policy.dart';
import '../state/trip_controller.dart';

/// ViewModel de la pantalla de viaje armado.
///
/// Escucha al [TripController] compartido: cada fix, edición o temporizador
/// manual se refleja en la UI sin recrear el estado.
class ArmedTripViewModel extends ChangeNotifier {
  ArmedTripViewModel({
    required this.controller,
    required this.actuator,
  }) {
    controller.addListener(_onControllerChanged);
  }

  final TripController controller;
  final WakeUpActuator actuator;

  Trip? get activeTrip => controller.activeTrip;
  TripAssessment? get assessment => controller.assessment;
  WakeUpStage get wakeUpStage => controller.wakeUpStage;
  bool get isArmed => controller.isArmed;
  TripIssue get issue => controller.issue;

  bool get isAlarming => wakeUpStage == WakeUpStage.audibleFallback;
  bool get isSnoozed => controller.isSnoozed;
  Duration? get snoozeRemaining => controller.snoozeRemaining;
  int get snoozesRemaining => controller.snoozesRemaining;
  bool get isManualArmed => controller.isManualArmed;
  Duration? get manualRemaining => controller.manualRemaining;

  String? get signalLabel {
    final confidence = assessment?.confidence;
    switch (confidence) {
      case TripConfidence.high:
        return 'Buena señal · actualización reciente';
      case TripConfidence.degraded:
        return 'Señal degradada · estimando con velocidad real';
      case TripConfidence.limited:
        return 'Señal limitada · estimando sin GPS nuevo';
      case null:
        return null;
    }
  }

  /// Distancia restante legible; incluye la extrapolación sin GPS.
  String get distanceLabel {
    final meters = assessment?.remainingMeters;
    if (meters == null) return '--';
    if (meters >= 1000) return '${(meters / 1000).toStringAsFixed(1)} km';
    return '${meters.round()} m';
  }

  /// ETA legible a partir de la velocidad real del último fix.
  String get etaLabel {
    final seconds = assessment?.etaSeconds;
    if (seconds == null) return '--';
    if (seconds <= 60) return '<1 min';
    return '${(seconds / 60).ceil()} min';
  }

  /// Confirma que el usuario está despierto y cierra el viaje.
  Future<void> finishAfterWake() async {
    await controller.finish();
    notifyListeners();
  }

  /// Cancela el viaje armado.
  Future<void> cancel() async {
    await controller.cancel();
    notifyListeners();
  }

  /// Cambia el margen sin cancelar y re-armar.
  Future<void> editLeadTime(int minutes) async {
    await controller.editActiveTrip(
      alertLeadTime: Duration(minutes: minutes),
    );
    notifyListeners();
  }

  /// Cambia el destino sin cancelar y re-armar.
  Future<void> editDestination(GeoPoint destination, TransportMode mode) async {
    await controller.editActiveTrip(destination: destination, mode: mode);
    notifyListeners();
  }

  /// Último recurso: alarma por tiempo si el GPS no coopera.
  Future<void> startManualTimer(Duration duration) async {
    await controller.startManualTimer(duration);
    notifyListeners();
  }

  void cancelManualTimer() {
    controller.cancelManualTimer();
    notifyListeners();
  }

  /// Reproduce una vibración de prueba en la etapa actual.
  Future<void> testVibration() async {
    await actuator.testPattern(wakeUpStage);
  }

  /// Envía una notificación de prueba.
  Future<void> testNotification({bool playSound = false}) async {
    await actuator.testNotification(playSound: playSound);
  }

  void _onControllerChanged() => notifyListeners();

  @override
  void dispose() {
    controller.removeListener(_onControllerChanged);
    super.dispose();
  }
}

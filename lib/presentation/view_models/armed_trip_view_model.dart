import 'package:flutter/foundation.dart';

import '../../data/alerts/local_notification_wake_up_actuator.dart';
import '../../domain/entities/trip.dart';
import '../../domain/services/trip_monitor.dart';
import '../../domain/services/wake_up_policy.dart';
import '../state/trip_controller.dart';

/// ViewModel de la pantalla de viaje armado.
///
/// Expone el estado del viaje, la evaluación de llegada y la etapa de alarma
/// para la UI, delegando la lógica de negocio en [TripController].
class ArmedTripViewModel extends ChangeNotifier {
  ArmedTripViewModel({
    required this.controller,
    required this.actuator,
  });

  final TripController controller;
  final LocalNotificationWakeUpActuator actuator;

  Trip? get activeTrip => controller.activeTrip;
  TripAssessment? get assessment => controller.assessment;
  WakeUpStage get wakeUpStage => controller.wakeUpStage;
  bool get isArmed => controller.isArmed;
  TripIssue get issue => controller.issue;

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

  bool get isAlarming => wakeUpStage != WakeUpStage.monitoring;

  /// Confirma que el usuario está despierto.
  void acknowledgeAlarm() {
    controller.acknowledgeAlarm();
    notifyListeners();
  }

  /// Cancela el viaje armado.
  Future<void> cancel() async {
    await controller.cancel();
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
}

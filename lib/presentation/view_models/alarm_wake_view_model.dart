import 'package:flutter/foundation.dart';

import '../../data/alerts/local_notification_wake_up_actuator.dart';
import '../../domain/entities/trip.dart';
import '../../domain/services/wake_up_policy.dart';
import '../state/trip_controller.dart';

/// ViewModel de la pantalla de alarma a pantalla completa.
///
/// No reprograma nada por su cuenta: delega en [TripController], que es el
/// único dueño del temporizador de posponer y del límite de pospones. Así la
/// alarma de la notificación y la de la pantalla comparten el mismo estado.
class AlarmWakeViewModel extends ChangeNotifier {
  AlarmWakeViewModel({
    required this.controller,
    required this.actuator,
    required this.trip,
  }) {
    controller.addListener(_onControllerChanged);
  }

  final TripController controller;
  final LocalNotificationWakeUpActuator actuator;
  final Trip trip;

  WakeUpStage get wakeUpStage => controller.wakeUpStage;
  TripIssue get issue => controller.issue;
  bool get isArmed => controller.isArmed;

  bool get isSnoozing => controller.isSnoozed;
  DateTime? get snoozeWakeUpTime => controller.snoozeUntil;
  int get snoozeCount => controller.snoozeCount;
  bool get maxSnoozesReached => !controller.canSnooze;
  int get snoozesRemaining => controller.snoozesRemaining;

  /// Confirma que el usuario está despierto y cierra el viaje.
  Future<void> acknowledgeAndFinish() async {
    await controller.finish();
    notifyListeners();
  }

  /// Cancela la alarma y el viaje.
  Future<void> cancel() async {
    await controller.cancel();
    notifyListeners();
  }

  /// Pospone la alarma por [minutes] minutos.
  Future<void> snooze(int minutes) async {
    await controller.snooze(duration: Duration(minutes: minutes));
    notifyListeners();
  }

  /// Detiene el sonido de alarma sin cancelar el viaje.
  Future<void> stopSound() async {
    await actuator.clear();
    notifyListeners();
  }

  void _onControllerChanged() => notifyListeners();

  @override
  void dispose() {
    controller.removeListener(_onControllerChanged);
    super.dispose();
  }
}

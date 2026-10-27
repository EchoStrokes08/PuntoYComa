import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/alerts/local_notification_wake_up_actuator.dart';
import '../../domain/entities/trip.dart';
import '../../domain/services/wake_up_policy.dart';
import '../state/trip_controller.dart';

/// ViewModel de la pantalla de alarma a pantalla completa.
///
/// Gestiona el estado de alarma sonora, las opciones de posponer y la
/// confirmación de despertar con alto contraste para máxima visibilidad.
class AlarmWakeViewModel extends ChangeNotifier {
  AlarmWakeViewModel({
    required this.controller,
    required this.actuator,
    required this.trip,
  });

  final TripController controller;
  final LocalNotificationWakeUpActuator actuator;
  final Trip trip;

  WakeUpStage get wakeUpStage => controller.wakeUpStage;
  TripIssue get issue => controller.issue;
  bool get isArmed => controller.isArmed;

  bool _isSnoozing = false;
  int _snoozeMinutes = 1;
  int _snoozeCount = 0;
  static const int maxSnoozes = 3;
  Timer? _snoozeTimer;
  DateTime? _snoozeWakeUpTime;

  bool get isSnoozing => _isSnoozing;
  int get snoozeMinutes => _snoozeMinutes;
  int get snoozeCount => _snoozeCount;
  bool get maxSnoozesReached => _snoozeCount >= maxSnoozes;
  int get snoozesRemaining => (maxSnoozes - _snoozeCount).clamp(0, maxSnoozes);
  DateTime? get snoozeWakeUpTime => _snoozeWakeUpTime;

  /// Confirma que el usuario está despierto y detiene la alarma.
  void acknowledge() {
    _cancelSnoozeTimer();
    controller.acknowledgeAlarm();
    notifyListeners();
  }

  /// Cancela la alarma y el viaje.
  Future<void> cancel() async {
    _cancelSnoozeTimer();
    await controller.cancel();
    notifyListeners();
  }

  /// Cambia los minutos de posponer.
  void setSnoozeMinutes(int minutes) {
    _snoozeMinutes = minutes;
    notifyListeners();
  }

  /// Pospone la alarma por [snoozeMinutes] minutos.
  ///
  /// Reprograma una alarma futura que se disparará después del tiempo de
  /// posponer. Si se alcanza el límite de pospones, se deshabilita la opción.
  Future<void> snooze() async {
    if (_isSnoozing || maxSnoozesReached) return;

    _isSnoozing = true;
    _snoozeCount++;
    _snoozeWakeUpTime = DateTime.now().add(Duration(minutes: _snoozeMinutes));
    notifyListeners();

    _cancelSnoozeTimer();
    _snoozeTimer = Timer(Duration(minutes: _snoozeMinutes), () {
      _isSnoozing = false;
      _snoozeWakeUpTime = null;
      notifyListeners();
      // Re-evaluar: la alarma debería sonar de nuevo
      controller.acknowledgeAlarm(); // esto resetea para la siguiente evaluación
      notifyListeners();
    });
  }

  /// Detiene el sonido de alarma sin cancelar el viaje.
  Future<void> stopSound() async {
    await actuator.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _cancelSnoozeTimer();
    super.dispose();
  }

  void _cancelSnoozeTimer() {
    _snoozeTimer?.cancel();
    _snoozeTimer = null;
  }
}
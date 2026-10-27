import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../domain/services/platform_contracts.dart';
import '../../domain/services/wake_up_policy.dart';

/// Implements the escalating wake-up contract with gradual haptics, local
/// notifications and a final audible full-screen alert. The alarm does not
/// depend on the backend; notifications are local by definition.
class LocalNotificationWakeUpActuator implements WakeUpActuator {
  FlutterLocalNotificationsPlugin? _plugin;
  WakeUpStage? _lastStage;
  bool _soundAtEnd = false;

  /// Configures whether the final stage plays a sound ("Sonido al final").
  void configure({required bool soundAtEnd}) => _soundAtEnd = soundAtEnd;

  static bool _initialized = false;

  Future<bool> _ensurePlugin() async {
    if (_initialized) return _plugin != null;
    _plugin ??= FlutterLocalNotificationsPlugin();
    try {
      _initialized =
          await _plugin!.initialize(
                settings: const InitializationSettings(
                  android: AndroidInitializationSettings('@mipmap/ic_launcher'),
                  iOS: DarwinInitializationSettings(),
                ),
              ) ??
              false;
    } on MissingPluginException {
      _initialized = false;
    }
    return _initialized;
  }

  @override
  Future<void> setStage(WakeUpStage stage) async {
    if (stage == _lastStage) return;
    _lastStage = stage;
    switch (stage) {
      case WakeUpStage.monitoring:
        await _cancelNotifications();
      case WakeUpStage.gentleHaptic:
        await HapticFeedback.lightImpact();
        await _cancelNotifications();
      case WakeUpStage.persistentHaptic:
        await HapticFeedback.mediumImpact();
        await _persistHapticNotification();
      case WakeUpStage.audibleFallback:
        await HapticFeedback.heavyImpact();
        await _audibleAlert();
    }
  }

  @override
  Future<void> showPreventiveSignalLossAlert() async {
    // Uncertainty must wake the rider up, never lull them: the preventive
    // alert asks for attention without waiting for the next GPS fix.
    await _notify(
      id: _preventiveId,
      title: 'Señal perdida',
      body:
          'No recibimos posición confiable. Sonaremos en tu parada con la '
          'información que ya tenemos. Mantente atento.',
      fullScreen: false,
      playSound: true,
      vibration: true,
    );
  }

  @override
  Future<void> clear() async {
    _lastStage = null;
    await _cancelNotifications();
  }

  @override
  Future<void> testPattern(WakeUpStage stage) async {
    await _ensurePlugin();
    switch (stage) {
      case WakeUpStage.monitoring:
        await HapticFeedback.lightImpact();
      case WakeUpStage.gentleHaptic:
        await HapticFeedback.lightImpact();
      case WakeUpStage.persistentHaptic:
        await HapticFeedback.mediumImpact();
      case WakeUpStage.audibleFallback:
        await HapticFeedback.heavyImpact();
    }
  }

  @override
  Future<void> testNotification({bool playSound = false}) async {
    await _notify(
      id: 99,
      title: 'Prueba de notificación',
      body: 'Esta es una prueba de alarma de PuntoYcoma.',
      fullScreen: false,
      playSound: playSound && _soundAtEnd,
      vibration: true,
    );
  }

  Future<void> _persistHapticNotification() => _notify(
    id: _alarmId,
    title: 'Preparándose tu parada',
    body: 'Vibraciones persistentes activadas. Confirmar cuando despiertes.',
    fullScreen: false,
    playSound: false,
    vibration: true,
  );

  Future<void> _audibleAlert() => _notify(
    id: _alarmId,
    title: 'Tu parada se acerca',
    body: 'Alarma sonora activa. Prepara tu salida.',
    fullScreen: true,
    playSound: _soundAtEnd,
    vibration: true,
  );

  static const _alarmId = 1;
  static const _preventiveId = 2;

  Future<void> _notify({
    required int id,
    required String title,
    required String body,
    required bool fullScreen,
    required bool playSound,
    required bool vibration,
  }) async {
    final initialized = await _ensurePlugin();
    if (!initialized) return;
    final vibrationPattern = Int64List.fromList([0, 220, 180, 220, 180, 380]);
    await _plugin!.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'punto_y_coma.wake_up',
          'Despertar en la parada',
          channelDescription: 'Vibración gradual y aviso final de llegada',
          importance: Importance.max,
          priority: Priority.max,
          category: AndroidNotificationCategory.alarm,
          fullScreenIntent: fullScreen,
          playSound: playSound,
          enableVibration: vibration,
          vibrationPattern: vibrationPattern,
          ongoing: true,
          autoCancel: false,
        ),
        iOS: const DarwinNotificationDetails(
          presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
    );
  }

  Future<void> _cancelNotifications() async {
    final initialized = await _ensurePlugin();
    if (!initialized) return;
    await _plugin!.cancel(id: _alarmId);
    await _plugin!.cancel(id: _preventiveId);
  }
}

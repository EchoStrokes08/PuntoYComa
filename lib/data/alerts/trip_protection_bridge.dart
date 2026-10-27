import 'package:flutter/services.dart';

/// Bridges Dart's controller to Android's native foreground service so the
/// armed trip cannot be reaped while the screen is off. Fails open silently
/// on other platforms and in tests (MissingPluginException).
class TripProtectionBridge {
  static const _channel = MethodChannel('punto_y_coma/protection');

  Future<void> setProtected(bool active) async {
    try {
      // The boot receiver reads this plain-prefs flag; write it first so a
      // reboot between both calls cannot start a service without a trip.
      await _channel.invokeMethod('setArmedFlag', {'armed': active});
      if (active) {
        await _channel.invokeMethod('startForeground');
      } else {
        await _channel.invokeMethod('stopForeground');
      }
    } on MissingPluginException {
      // Web/desktop/test: no native protection available.
    } on PlatformException {
      // Service control failures must not break arming the alarm.
    }
  }
}

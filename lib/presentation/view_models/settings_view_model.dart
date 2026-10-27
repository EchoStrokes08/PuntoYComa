import 'package:flutter/material.dart';

/// ViewModel de la pantalla de ajustes.
///
/// Gestiona la configuración de la app: modo de tema, fuerza de háptica,
/// volumen de alarma y preferencias de notificación.
class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel();

  ThemeMode _themeMode = ThemeMode.system;
  double _hapticStrength = 1.0; // 0.0 = suave, 1.0 = fuerte
  bool _alarmSoundEnabled = true;
  bool _notificationsEnabled = true;
  int _locationProfileThreshold = 3000; // metros para cambiar a pasivo

  ThemeMode get themeMode => _themeMode;
  double get hapticStrength => _hapticStrength;
  bool get alarmSoundEnabled => _alarmSoundEnabled;
  bool get notificationsEnabled => _notificationsEnabled;
  int get locationProfileThreshold => _locationProfileThreshold;

  /// Cambia el modo de tema.
  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  /// Cambia la fuerza de háptica (0.0 a 1.0).
  void setHapticStrength(double strength) {
    _hapticStrength = strength.clamp(0.0, 1.0);
    notifyListeners();
  }

  /// Cambia si el alarma suena al final.
  void setAlarmSoundEnabled(bool enabled) {
    _alarmSoundEnabled = enabled;
    notifyListeners();
  }

  /// Cambia si las notificaciones están habilitadas.
  void setNotificationsEnabled(bool enabled) {
    _notificationsEnabled = enabled;
    notifyListeners();
  }

  /// Cambia el umbral de distancia para el perfil de ubicación pasivo.
  void setLocationProfileThreshold(int meters) {
    _locationProfileThreshold = meters.clamp(1000, 5000);
    notifyListeners();
  }
}

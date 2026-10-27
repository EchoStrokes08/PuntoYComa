import 'package:flutter/foundation.dart';

import '../../domain/entities/trip.dart';
import '../../domain/services/platform_contracts.dart';
import '../../domain/services/wake_up_policy.dart';

/// ViewModel de la pantalla de preparación.
///
/// Gestiona el margen de anticipación, la preferencia de sonido y la
/// demostración de vibración antes de armar la alarma.
class PreparationViewModel extends ChangeNotifier {
  PreparationViewModel({required this.actuator});

  final WakeUpActuator actuator;

  int _leadMinutes = 4;
  bool _soundAtEnd = false;
  bool _isTestingVibration = false;
  bool _isTestingNotification = false;

  int get leadMinutes => _leadMinutes;
  bool get soundAtEnd => _soundAtEnd;
  bool get isTestingVibration => _isTestingVibration;
  bool get isTestingNotification => _isTestingNotification;

  /// Cambia el margen de anticipación.
  void setLeadMinutes(int minutes) {
    _leadMinutes = minutes;
    notifyListeners();
  }

  /// Cambia la preferencia de sonido al final.
  void setSoundAtEnd(bool value) {
    _soundAtEnd = value;
    actuator.configure(soundAtEnd: value);
    notifyListeners();
  }

  /// Reproduce una vibración de prueba (sin iniciar alarma).
  Future<void> testVibration() async {
    _isTestingVibration = true;
    notifyListeners();

    try {
      await actuator.testPattern(WakeUpStage.gentleHaptic);
    } finally {
      _isTestingVibration = false;
      notifyListeners();
    }
  }

  /// Envía una notificación de prueba.
  Future<void> testNotification() async {
    _isTestingNotification = true;
    notifyListeners();

    try {
      await actuator.testNotification(playSound: _soundAtEnd);
    } finally {
      _isTestingNotification = false;
      notifyListeners();
    }
  }

  /// Crea un [Trip] draft con los valores actuales.
  Trip createDraft({
    required String id,
    required GeoPoint destination,
    required TransportMode mode,
  }) {
    return Trip(
      id: id,
      destination: destination,
      mode: mode,
      status: TripStatus.draft,
      alertLeadTime: Duration(minutes: _leadMinutes),
    );
  }
}

import 'package:flutter/foundation.dart';

import '../../domain/services/platform_contracts.dart';
import '../../domain/services/wake_up_policy.dart';

/// ViewModel de la pantalla de bienvenida.
///
/// Gestiona la demostración háptica opcional y el estado de inicio del flujo.
class WelcomeViewModel extends ChangeNotifier {
  WelcomeViewModel({required this.actuator});

  final WakeUpActuator actuator;

  bool _vibrationDemoPlayed = false;
  bool _isDemoPlaying = false;

  bool get vibrationDemoPlayed => _vibrationDemoPlayed;
  bool get isDemoPlaying => _isDemoPlaying;

  /// Reproduce el patrón háptico suave como demostración de bienvenida.
  Future<void> playHapticDemo() async {
    if (_isDemoPlaying) return;
    _isDemoPlaying = true;
    notifyListeners();

    try {
      await actuator.testPattern(WakeUpStage.gentleHaptic);
      _vibrationDemoPlayed = true;
      notifyListeners();
    } finally {
      _isDemoPlaying = false;
      notifyListeners();
    }
  }

  /// Indica que el usuario comenzó el flujo de creación de alarma.
  void startFlow() {
    _vibrationDemoPlayed = false;
    notifyListeners();
  }
}

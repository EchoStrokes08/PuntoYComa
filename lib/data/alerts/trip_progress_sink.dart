import '../../domain/services/trip_progress_contracts.dart';
import 'trip_protection_bridge.dart';

/// Publica el progreso del viaje en la notificación ongoing de Android.
///
/// La app funciona igual en web/escritorio: el bridge ignora el canal ausente.
class AndroidTripProgressSink implements TripProgressSink {
  const AndroidTripProgressSink({
    TripProtectionBridge bridge = const TripProtectionBridge(),
  }) : _bridge = bridge;

  final TripProtectionBridge _bridge;

  @override
  Future<void> update(TripProgress progress) {
    return _bridge.updateProgress(
      title: progress.title,
      body: progress.body,
      percent: progress.percent,
    );
  }

  @override
  Future<void> clear() => _bridge.clearProgress();
}

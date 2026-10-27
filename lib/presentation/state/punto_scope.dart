import 'package:flutter/widgets.dart';

import '../../data/alerts/local_notification_wake_up_actuator.dart';
import '../../data/location/geolocator_location_source.dart';
import '../../domain/services/trip_history_contracts.dart';
import 'trip_controller.dart';

/// Alcance de dependencias de la app.
///
/// Las pantallas leen un único [TripController] compartido: armar, editar,
/// posponer y confirmar la alarma ocurren sobre el mismo estado. Sin este
/// alcance cada pantalla creaba su propio controlador y el viaje armado se
/// perdía al navegar.
class PuntoScope extends InheritedNotifier<TripController> {
  const PuntoScope({
    super.key,
    required TripController controller,
    required this.actuator,
    required this.locationSource,
    required this.historyRepository,
    required super.child,
  }) : super(notifier: controller);

  final LocalNotificationWakeUpActuator actuator;
  final GeolocatorLocationSource locationSource;
  final TripHistoryRepository historyRepository;

  TripController get controller => notifier!;

  static PuntoScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PuntoScope>();

  static PuntoScope of(BuildContext context) {
    final scope = maybeOf(context);
    assert(scope != null, 'PuntoScope no encontrado en el árbol de widgets.');
    return scope!;
  }
}

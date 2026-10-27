import 'package:flutter/widgets.dart';

import '../../domain/services/platform_contracts.dart';
import '../../domain/services/trip_history_contracts.dart';
import 'trip_controller.dart';

/// Alcance de dependencias de la app.
///
/// Las pantallas leen un único [TripController] compartido: armar, editar,
/// posponer y confirmar la alarma ocurren sobre el mismo estado. Sin este
/// alcance cada pantalla creaba su propio controlador y el viaje armado se
/// perdía al navegar.
///
/// Los campos usan los contratos de dominio ([WakeUpActuator], [LocationSource]),
/// no las implementaciones nativas: así las pruebas pueden inyectar falsos
/// que no tocan plugins.
class PuntoScope extends InheritedNotifier<TripController> {
  const PuntoScope({
    super.key,
    required TripController controller,
    required this.actuator,
    required this.locationSource,
    required this.historyRepository,
    required super.child,
  }) : super(notifier: controller);

  final WakeUpActuator actuator;
  final LocationSource locationSource;
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

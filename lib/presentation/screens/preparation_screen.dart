import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/alerts/local_notification_wake_up_actuator.dart';
import '../../data/routing/local_stop_cache.dart';
import '../../domain/entities/trip.dart';
import '../../design/design.dart';
import '../animations/animations.dart';
import '../state/punto_scope.dart';
import '../view_models/view_models.dart';

/// Pantalla de preparación: margen, sonido y armado de alarma.
///
/// El contenido configura el viaje; las acciones (probar vibración/notificación
/// y el CTA de armar) quedan fijas abajo para que siempre sean alcanzables.
///
/// Fase D: el armado pasa por la pantalla de permiso en contexto, que arma el
/// viaje en el controlador compartido antes de navegar al radar.
class PreparationScreen extends StatefulWidget {
  const PreparationScreen({super.key, required this.stop});

  final CachedStop stop;

  @override
  State<PreparationScreen> createState() => _PreparationScreenState();
}

class _PreparationScreenState extends State<PreparationScreen> {
  PreparationViewModel? _viewModel;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final actuator =
        PuntoScope.maybeOf(context)?.actuator ??
        LocalNotificationWakeUpActuator();
    _viewModel = PreparationViewModel(actuator: actuator);
  }

  @override
  void dispose() {
    _viewModel?.dispose();
    super.dispose();
  }

  void _arm() {
    final viewModel = _viewModel;
    if (viewModel == null) return;
    final draft = viewModel.createDraft(
      id: 'trip-${DateTime.now().millisecondsSinceEpoch}',
      destination: GeoPoint(
        widget.stop.latitude,
        widget.stop.longitude,
      ),
      mode: widget.stop.mode,
    );
    context.push('/permisos', extra: draft);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = _viewModel;
    if (viewModel == null) {
      return const PuntoScaffold(child: SizedBox.shrink());
    }
    return PuntoScaffold(
      header: const PuntoScreenHeader(title: 'Prepara tu descanso'),
      bottomBar: AnimatedBuilder(
        animation: viewModel,
        builder: (context, _) => Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: PuntoOutlinedButton(
                    onPressed: viewModel.isTestingVibration
                        ? null
                        : viewModel.testVibration,
                    label: 'Probar vibración',
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.vibration_rounded, size: 18),
                        SizedBox(width: PuntoSpacing.xs),
                        Flexible(
                          child: Text(
                            'Probar',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: PuntoSpacing.s12),
                Expanded(
                  child: PuntoOutlinedButton(
                    onPressed: viewModel.isTestingNotification
                        ? null
                        : viewModel.testNotification,
                    label: 'Probar notificación',
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.notifications_rounded, size: 18),
                        SizedBox(width: PuntoSpacing.xs),
                        Flexible(
                          child: Text(
                            'Probar',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: PuntoSpacing.s12),
            PuntoButton(
              fullWidth: true,
              height: 56,
              borderRadius: PuntoBorders.lg,
              onPressed: _arm,
              label: 'Armar alarma',
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shield_moon_rounded, size: 20),
                  SizedBox(width: PuntoSpacing.sm),
                  Flexible(
                    child: Text(
                      'Armar alarma',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      child: SingleChildScrollView(
        child: StaggeredReveal(
          children: [
            const SizedBox(height: PuntoSpacing.sm),
            Text(
              'Configura cuántos minutos antes quieres despertarte.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: PuntoSpacing.lg),
            _DestinationCard(stop: widget.stop),
            const SizedBox(height: PuntoSpacing.lg),
            Text(
              'Avísame con',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: PuntoSpacing.sm),
            AnimatedBuilder(
              animation: viewModel,
              builder: (context, _) => SegmentedButton<int>(
                segments: const [
                  ButtonSegment(
                    value: 3,
                    label: Text('3 min'),
                  ),
                  ButtonSegment(
                    value: 4,
                    label: Text('4 min'),
                  ),
                  ButtonSegment(
                    value: 5,
                    label: Text('5 min'),
                  ),
                ],
                selected: {viewModel.leadMinutes},
                onSelectionChanged: (value) {
                  viewModel.setLeadMinutes(value.first);
                },
              ),
            ),
            const SizedBox(height: PuntoSpacing.md),
            AnimatedBuilder(
              animation: viewModel,
              builder: (context, _) => SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Sonido al final'),
                subtitle: const Text(
                  'Las vibraciones empiezan de forma suave.',
                ),
                value: viewModel.soundAtEnd,
                onChanged: viewModel.setSoundAtEnd,
              ),
            ),
            const SizedBox(height: PuntoSpacing.lg),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta del destino elegido: ícono de transporte en círculo tintado,
/// nombre y ruta sobre superficie blanca.
class _DestinationCard extends StatelessWidget {
  const _DestinationCard({required this.stop});

  final CachedStop stop;

  @override
  Widget build(BuildContext context) {
    return PuntoCard(
      color: context.surfaceBright,
      borderRadius: PuntoBorders.md,
      elevation: PuntoEffects.floating,
      padding: const EdgeInsets.all(PuntoSpacing.md),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.primaryContainer,
            ),
            child: Icon(
              stop.mode == TransportMode.metro
                  ? Icons.train_rounded
                  : Icons.directions_bus_rounded,
              size: 24,
              color: context.primary,
            ),
          ),
          const SizedBox(width: PuntoSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stop.name,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: PuntoSpacing.xs),
                Text(
                  stop.routeId ?? 'Parada seleccionada',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.onSurfaceLow,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/alerts/local_notification_wake_up_actuator.dart';
import '../../data/location/geolocator_location_source.dart';
import '../../data/persistence/secure_trip_repository.dart';
import '../../data/persistence/trip_history_repository.dart';
import '../../domain/entities/trip.dart';
import '../../domain/services/trip_monitor.dart';
import '../../domain/services/wake_up_policy.dart';
import '../../design/design.dart';
import '../animations/animations.dart';
import '../state/trip_controller.dart';
import '../view_models/view_models.dart';

/// Pantalla de viaje armado: estado, ETA, distancia y señal.
///
/// El radar respira para transmitir vigilancia activa; las acciones
/// (confirmar despertar, probar vibración, cancelar) quedan fijas abajo.
class ArmedTripScreen extends StatefulWidget {
  const ArmedTripScreen({super.key});

  @override
  State<ArmedTripScreen> createState() => _ArmedTripScreenState();
}

class _ArmedTripScreenState extends State<ArmedTripScreen> {
  late TripController _controller;
  late LocalNotificationWakeUpActuator _actuator;
  late ArmedTripViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _actuator = LocalNotificationWakeUpActuator();
    _controller = TripController(
      locationSource: const GeolocatorLocationSource(),
      tripRepository: SecureTripRepository(),
      tripHistoryRepository: TripHistoryRepositoryImpl(),
      wakeUpActuator: _actuator,
      requestPermission: () async => true,
      setForegroundProtection: (_) async {},
    );
    _viewModel = ArmedTripViewModel(
      controller: _controller,
      actuator: _actuator,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  String _stageLabel(WakeUpStage stage) {
    switch (stage) {
      case WakeUpStage.monitoring:
        return 'Vigilando la ruta';
      case WakeUpStage.gentleHaptic:
        return 'Vibración suave activa';
      case WakeUpStage.persistentHaptic:
        return 'Vibración insistente: confirma que despertaste';
      case WakeUpStage.audibleFallback:
        return 'Alarma sonora activa';
    }
  }

  @override
  Widget build(BuildContext context) {
    return PuntoScaffold(
      header: const PuntoBrandHeader(),
      child: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) => Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: PuntoSpacing.xl),
                    Center(
                      child: RadarPulse(
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _viewModel.isAlarming
                                  ? context.error
                                  : context.primary,
                              width: 5,
                            ),
                          ),
                          child: Icon(
                            Icons.radar_rounded,
                            size: 52,
                            color: _viewModel.isAlarming
                                ? context.error
                                : context.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: PuntoSpacing.xl),
                    Text(
                      _stageLabel(_viewModel.wakeUpStage),
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: PuntoSpacing.sm),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 300),
                      child: Text(
                        _viewModel.signalLabel ??
                            'Esperando tu primera posición…',
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: context.onSurfaceVariant,
                                ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_viewModel.assessment != null) ...[
                      const SizedBox(height: PuntoSpacing.md),
                      PuntoSignalChip(
                        signal: _viewModel
                                    .assessment!.confidence ==
                                TripConfidence.high
                            ? 'good'
                            : _viewModel.assessment!.confidence ==
                                    TripConfidence.degraded
                                ? 'degraded'
                                : 'limited',
                      ),
                    ],
                    if (_viewModel.activeTrip != null) ...[
                      const SizedBox(height: PuntoSpacing.lg),
                      _DestinationCard(trip: _viewModel.activeTrip!),
                    ],
                    const SizedBox(height: PuntoSpacing.lg),
                    Row(
                      children: [
                        Expanded(
                          child: PuntoMetricCard(
                            icon: Icons.schedule_rounded,
                            value: '-- min',
                            label: 'estimados',
                          ),
                        ),
                        const SizedBox(width: PuntoSpacing.md),
                        Expanded(
                          child: PuntoMetricCard(
                            icon: Icons.straighten_rounded,
                            value: '-- km',
                            label: 'restantes',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: PuntoSpacing.lg),
                  ],
                ),
              ),
            ),
            // ── Acciones fijas ─────────────────────────────────────────
            if (_viewModel.isAlarming) ...[
              PuntoButton(
                fullWidth: true,
                height: 56,
                borderRadius: PuntoBorders.lg,
                onPressed: _viewModel.acknowledgeAlarm,
                label: 'Ya desperté',
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.done_rounded, size: 20),
                    SizedBox(width: PuntoSpacing.sm),
                    Flexible(
                      child: Text(
                        'Ya desperté',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: PuntoSpacing.s12),
            ],
            PuntoOutlinedButton(
              fullWidth: true,
              onPressed: _viewModel.testVibration,
              label: 'Probar vibración',
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.vibration_rounded, size: 20),
                  SizedBox(width: PuntoSpacing.sm),
                  Flexible(
                    child: Text(
                      'Probar vibración',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            PuntoTextButton(
              onPressed: () {
                _viewModel.cancel();
                context.go('/');
              },
              label: 'Cancelar alarma',
              child: const Text('Cancelar alarma'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta del destino activo sobre superficie blanca.
class _DestinationCard extends StatelessWidget {
  const _DestinationCard({required this.trip});

  final Trip trip;

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
              trip.mode == TransportMode.metro
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
                  'Destino',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.onSurfaceLow,
                      ),
                ),
                const SizedBox(height: PuntoSpacing.xs),
                Text(
                  '${trip.destination.latitude.toStringAsFixed(4)}, '
                  '${trip.destination.longitude.toStringAsFixed(4)}',
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

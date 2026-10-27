import 'dart:async';

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
import '../state/punto_scope.dart';
import '../state/trip_controller.dart';
import '../view_models/view_models.dart';

/// Pantalla de viaje armado: estado, ETA, distancia y señal.
///
/// El radar respira para transmitir vigilancia activa; las acciones
/// (editar, temporizador manual, confirmar despertar, cancelar) quedan fijas
/// abajo. Cuando la etapa audible se dispara, la pantalla de alarma se abre
/// sola con el mismo controlador compartido.
class ArmedTripScreen extends StatefulWidget {
  const ArmedTripScreen({super.key, this.trip});

  /// Viaje con el que armar si se llega directo a la ruta (enlaces, pruebas).
  final Trip? trip;

  @override
  State<ArmedTripScreen> createState() => _ArmedTripScreenState();
}

class _ArmedTripScreenState extends State<ArmedTripScreen> {
  bool _initialized = false;
  bool _ownsController = false;
  bool _alarmRouteOpen = false;
  Timer? _clockTicker;

  late TripController _controller;
  late LocalNotificationWakeUpActuator _actuator;
  late ArmedTripViewModel _viewModel;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final scope = PuntoScope.maybeOf(context);
    _actuator = scope?.actuator ?? LocalNotificationWakeUpActuator();
    if (scope != null) {
      _controller = scope.controller;
    } else {
      _ownsController = true;
      _controller = TripController(
        locationSource: const GeolocatorLocationSource(),
        tripRepository: SecureTripRepository(),
        tripHistoryRepository: TripHistoryRepositoryImpl(),
        wakeUpActuator: _actuator,
        requestPermission: () async => true,
        setForegroundProtection: (_) async {},
      );
    }

    _viewModel = ArmedTripViewModel(
      controller: _controller,
      actuator: _actuator,
    )..addListener(_onViewModelChanged);

    final pending = widget.trip;
    if (pending != null && !_controller.isArmed) {
      unawaited(_controller.arm(pending));
    }

    // Refresca la cuenta regresiva de posponer / temporizador manual.
    _clockTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clockTicker?.cancel();
    _viewModel
      ..removeListener(_onViewModelChanged)
      ..dispose();
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    if (!mounted) return;
    if (_viewModel.isAlarming && !_alarmRouteOpen && !_viewModel.isSnoozed) {
      final trip = _viewModel.activeTrip;
      if (trip == null) return;
      _alarmRouteOpen = true;
      context.push('/alarma', extra: trip).whenComplete(() {
        _alarmRouteOpen = false;
      });
    }
  }

  Future<void> _finishAndGoHome() async {
    await _viewModel.finishAfterWake();
    if (mounted) context.go('/');
  }

  Future<void> _openEditSheet() async {
    final trip = _viewModel.activeTrip;
    if (trip == null) return;
    var leadMinutes = trip.alertLeadTime.inMinutes;

    final selected = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: context.surfaceBright,
      builder: (sheet) => StatefulBuilder(
        builder: (sheet, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
            PuntoSpacing.pagePadding,
            PuntoSpacing.sm,
            PuntoSpacing.pagePadding,
            PuntoSpacing.md + MediaQuery.viewInsetsOf(sheet).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Editar viaje',
                style: Theme.of(sheet).textTheme.headlineSmall,
              ),
              const SizedBox(height: PuntoSpacing.xs),
              Text(
                'La vigilancia continúa: solo cambia el aviso.',
                style: Theme.of(sheet).textTheme.bodySmall?.copyWith(
                      color: sheet.onSurfaceLow,
                    ),
              ),
              const SizedBox(height: PuntoSpacing.lg),
              Text(
                'Avísame con',
                style: Theme.of(sheet).textTheme.titleMedium,
              ),
              const SizedBox(height: PuntoSpacing.sm),
              Wrap(
                spacing: PuntoSpacing.sm,
                runSpacing: PuntoSpacing.sm,
                children: [
                  for (final minutes in const [2, 3, 4, 5, 8, 10])
                    ChoiceChip(
                      label: Text('$minutes min'),
                      selected: leadMinutes == minutes,
                      materialTapTargetSize:
                          MaterialTapTargetSize.padded,
                      onSelected: (_) =>
                          setSheet(() => leadMinutes = minutes),
                    ),
                ],
              ),
              const SizedBox(height: PuntoSpacing.lg),
              PuntoOutlinedButton(
                fullWidth: true,
                onPressed: () {
                  Navigator.of(sheet).pop();
                  context.push('/destino', extra: true);
                },
                label: 'Cambiar destino',
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_location_alt_rounded, size: 20),
                    SizedBox(width: PuntoSpacing.sm),
                    Flexible(
                      child: Text(
                        'Cambiar destino',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: PuntoSpacing.sm),
              PuntoButton(
                fullWidth: true,
                onPressed: () => Navigator.of(sheet).pop(leadMinutes),
                label: 'Guardar cambios',
                child: const Text('Guardar cambios'),
              ),
            ],
          ),
        ),
      ),
    );

    if (selected != null) {
      await _viewModel.editLeadTime(selected);
    }
  }

  Future<void> _openManualTimerSheet() async {
    final minutes = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: context.surfaceBright,
      builder: (sheet) => Padding(
        padding: EdgeInsets.fromLTRB(
          PuntoSpacing.pagePadding,
          PuntoSpacing.sm,
          PuntoSpacing.pagePadding,
          PuntoSpacing.md + MediaQuery.viewInsetsOf(sheet).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Temporizador manual',
              style: Theme.of(sheet).textTheme.headlineSmall,
            ),
            const SizedBox(height: PuntoSpacing.xs),
            Text(
              'Último recurso si la ubicación falla: la alarma sonará al '
              'cumplirse el tiempo, aunque no haya GPS.',
              style: Theme.of(sheet).textTheme.bodySmall?.copyWith(
                    color: sheet.onSurfaceLow,
                    height: 1.4,
                  ),
            ),
            const SizedBox(height: PuntoSpacing.lg),
            Wrap(
              spacing: PuntoSpacing.sm,
              runSpacing: PuntoSpacing.sm,
              children: [
                for (final option in const [5, 10, 15, 20, 30])
                  ActionChip(
                    label: Text('$option min'),
                    materialTapTargetSize: MaterialTapTargetSize.padded,
                    onPressed: () => Navigator.of(sheet).pop(option),
                  ),
              ],
            ),
            if (_viewModel.isManualArmed) ...[
              const SizedBox(height: PuntoSpacing.lg),
              PuntoTextButton(
                onPressed: () {
                  Navigator.of(sheet).pop();
                  _viewModel.cancelManualTimer();
                },
                label: 'Cancelar temporizador actual',
                child: const Text('Cancelar temporizador actual'),
              ),
            ],
          ],
        ),
      ),
    );

    if (minutes != null) {
      await _viewModel.startManualTimer(Duration(minutes: minutes));
    }
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

  String _formatCountdown(Duration? duration) {
    if (duration == null) return '--:--';
    final total = duration.inSeconds;
    final minutes = (total ~/ 60).toString().padLeft(2, '0');
    final seconds = (total % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return PuntoScaffold(
      header: PuntoBrandHeader(
        trailing: Semantics(
          label: 'Historial',
          button: true,
          child: IconButton(
            icon: const Icon(Icons.history_rounded, size: 22),
            onPressed: () => context.push('/historial'),
          ),
        ),
      ),
      child: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) => Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: PuntoSpacing.lg),
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
                    if (_viewModel.isSnoozed) ...[
                      const SizedBox(height: PuntoSpacing.md),
                      _SnoozeCard(
                        remaining: _formatCountdown(_viewModel.snoozeRemaining),
                        snoozesRemaining: _viewModel.snoozesRemaining,
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
                            value: _viewModel.etaLabel,
                            label: 'estimados',
                          ),
                        ),
                        const SizedBox(width: PuntoSpacing.md),
                        Expanded(
                          child: PuntoMetricCard(
                            icon: Icons.straighten_rounded,
                            value: _viewModel.distanceLabel,
                            label: 'restantes',
                          ),
                        ),
                      ],
                    ),
                    if (_viewModel.isManualArmed) ...[
                      const SizedBox(height: PuntoSpacing.lg),
                      _ManualTimerCard(
                        remaining: _formatCountdown(_viewModel.manualRemaining),
                        onCancel: _viewModel.cancelManualTimer,
                      ),
                    ],
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
                onPressed: _finishAndGoHome,
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
            Row(
              children: [
                Expanded(
                  child: PuntoOutlinedButton(
                    onPressed: _openEditSheet,
                    label: 'Editar viaje',
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.tune_rounded, size: 18),
                        SizedBox(width: PuntoSpacing.xs),
                        Flexible(
                          child: Text(
                            'Editar',
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
                    onPressed: _openManualTimerSheet,
                    label: 'Temporizador manual',
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.timer_outlined, size: 18),
                        SizedBox(width: PuntoSpacing.xs),
                        Flexible(
                          child: Text(
                            'Temporizador',
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
              onPressed: () async {
                await _viewModel.cancel();
                if (context.mounted) context.go('/');
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
                  'Destino activo',
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

/// Tarjeta que muestra la cuenta regresiva del posponer.
class _SnoozeCard extends StatelessWidget {
  const _SnoozeCard({
    required this.remaining,
    required this.snoozesRemaining,
  });

  final String remaining;
  final int snoozesRemaining;

  @override
  Widget build(BuildContext context) {
    return PuntoCard(
      color: context.primaryContainer,
      borderRadius: PuntoBorders.md,
      elevation: PuntoEffects.soft,
      padding: const EdgeInsets.all(PuntoSpacing.md),
      child: Row(
        children: [
          Icon(Icons.snooze_rounded, color: context.primary, size: 24),
          const SizedBox(width: PuntoSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Alarma pospuesta · $remaining',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  'Pospones restantes: $snoozesRemaining',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.onSurfaceVariant,
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

/// Tarjeta del temporizador manual activo con acción para cancelarlo.
class _ManualTimerCard extends StatelessWidget {
  const _ManualTimerCard({
    required this.remaining,
    required this.onCancel,
  });

  final String remaining;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return PuntoCard(
      color: context.alarmContainer,
      borderRadius: PuntoBorders.md,
      elevation: PuntoEffects.soft,
      padding: const EdgeInsets.all(PuntoSpacing.md),
      child: Row(
        children: [
          Icon(Icons.timer_rounded, color: context.alarm, size: 24),
          const SizedBox(width: PuntoSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Temporizador manual · $remaining',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  'La alarma sonará aunque el GPS falle.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          Semantics(
            label: 'Cancelar temporizador manual',
            button: true,
            child: IconButton(
              icon: Icon(Icons.close_rounded, color: context.alarm),
              onPressed: onCancel,
            ),
          ),
        ],
      ),
    );
  }
}

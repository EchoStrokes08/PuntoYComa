import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/alerts/local_notification_wake_up_actuator.dart';
import '../../data/location/geolocator_location_source.dart';
import '../../data/persistence/secure_trip_repository.dart';
import '../../data/persistence/trip_history_repository.dart';
import '../../domain/entities/trip.dart';
import '../../design/design.dart';
import '../state/punto_scope.dart';
import '../state/trip_controller.dart';
import '../view_models/view_models.dart';

/// Pantalla de alarma a pantalla completa con alto contraste.
///
/// Se muestra cuando suena la alarma sonora, con botones grandes para
/// confirmar despertar o posponer (1, 3 o 5 min). Deliberadamente no usa el
/// tema normal: fondo naranja de alarma, tinta blanca y CTA blanco con tinta
/// oscura. El posponer vive en el controlador compartido, igual que la
/// acción "Posponer" de la notificación.
class AlarmWakeScreen extends StatefulWidget {
  const AlarmWakeScreen({super.key, required this.trip});

  final Trip trip;

  @override
  State<AlarmWakeScreen> createState() => _AlarmWakeScreenState();
}

class _AlarmWakeScreenState extends State<AlarmWakeScreen>
    with SingleTickerProviderStateMixin {
  bool _initialized = false;
  bool _ownsController = false;
  late TripController _controller;
  late LocalNotificationWakeUpActuator _actuator;
  late AlarmWakeViewModel _viewModel;
  late AnimationController _pulseController;
  Timer? _clockTicker;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

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
    // El viaje ya llega armado desde el radar; no se rearma aquí para no
    // reiniciar el presupuesto de pospones ni volver a pedir permisos.
    _viewModel = AlarmWakeViewModel(
      controller: _controller,
      actuator: _actuator,
      trip: widget.trip,
    );

    _clockTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clockTicker?.cancel();
    _viewModel.dispose();
    if (_ownsController) _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  String _formatCountdown(DateTime? wakeUpTime) {
    if (wakeUpTime == null) return '';
    final diff = wakeUpTime.difference(DateTime.now());
    if (diff.isNegative) return 'ahora';
    final minutes = diff.inMinutes.remainder(60);
    final seconds = diff.inSeconds.remainder(60);
    return "${minutes.toString().padLeft(2, '0')}:"
        "${seconds.toString().padLeft(2, '0')}";
  }

  Future<void> _acknowledge() async {
    await _viewModel.acknowledgeAndFinish();
    if (mounted) context.go('/');
  }

  Future<void> _cancel() async {
    await _viewModel.cancel();
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final onAlarm = context.onAlarm;

    return PuntoScaffold(
      backgroundColor: context.alarm,
      header: PuntoBrandHeader(
        centered: true,
        dotColor: onAlarm,
        textColor: onAlarm,
      ),
      child: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) => Column(
          children: [
            const Spacer(),

            // ── Indicador visual de alarma con parpadeo ───────────────
            Center(
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final scale = 1.0 + (_pulseController.value * 0.1);
                  return Transform.scale(scale: scale, child: child);
                },
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: onAlarm.withValues(alpha: 0.2),
                    border: Border.all(color: onAlarm, width: 3),
                  ),
                  child: Icon(
                    _viewModel.isSnoozing
                        ? Icons.snooze_rounded
                        : Icons.notifications_active_rounded,
                    size: 48,
                    color: onAlarm,
                  ),
                ),
              ),
            ),
            const SizedBox(height: PuntoSpacing.xl),
            Text(
              _viewModel.isSnoozing
                  ? 'Alarma pospuesta'
                  : 'Tu parada se acerca',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: onAlarm,
                    fontWeight: FontWeight.w700,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: PuntoSpacing.md),
            Text(
              _viewModel.isSnoozing
                  ? 'Volverá a sonar en '
                      '${_formatCountdown(_viewModel.snoozeWakeUpTime)}.'
                  : 'Prepara tu salida. Confirma que estás despierto.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: onAlarm.withValues(alpha: 0.92),
                  ),
              textAlign: TextAlign.center,
            ),

            // ── Estado de snooze ──────────────────────────────────────
            if (_viewModel.isSnoozing) ...[
              const SizedBox(height: PuntoSpacing.md),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: PuntoSpacing.md,
                  vertical: PuntoSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: PuntoColors.alarmScrim,
                  borderRadius: BorderRadius.circular(PuntoBorders.circle),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.snooze_rounded, color: onAlarm, size: 20),
                    const SizedBox(width: PuntoSpacing.xs),
                    Text(
                      'Pospones restantes: ${_viewModel.snoozesRemaining}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: onAlarm,
                          ),
                    ),
                  ],
                ),
              ),
            ],
            const Spacer(),

            // ── Botones grandes y accesibles ─────────────────────────
            PuntoButton(
              fullWidth: true,
              height: 56,
              borderRadius: PuntoBorders.lg,
              onPressed: _acknowledge,
              label: 'Ya desperté',
              backgroundColor: onAlarm,
              foregroundColor: PuntoColors.alarmInk,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_rounded, size: 20),
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
            const SizedBox(height: PuntoSpacing.md),
            if (!_viewModel.maxSnoozesReached) ...[
              Row(
                children: [
                  for (final minutes in const [1, 3, 5]) ...[
                    if (minutes != 1)
                      const SizedBox(width: PuntoSpacing.sm),
                    Expanded(
                      child: PuntoOutlinedButton(
                        height: 52,
                        onPressed: () => _viewModel.snooze(minutes),
                        label: 'Posponer $minutes min',
                        foregroundColor: onAlarm,
                        backgroundColor: PuntoColors.alarmScrim,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.snooze_rounded, size: 18),
                            const SizedBox(width: PuntoSpacing.xs),
                            Flexible(
                              child: Text(
                                '$minutes min',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: PuntoSpacing.sm),
              Text(
                'Pospones restantes: ${_viewModel.snoozesRemaining}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: onAlarm.withValues(alpha: 0.75),
                    ),
              ),
            ] else
              Container(
                padding: const EdgeInsets.all(PuntoSpacing.md),
                decoration: BoxDecoration(
                  color: PuntoColors.alarmScrim,
                  borderRadius: BorderRadius.circular(PuntoBorders.md),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      color: onAlarm.withValues(alpha: 0.8),
                      size: 20,
                    ),
                    const SizedBox(width: PuntoSpacing.xs),
                    Flexible(
                      child: Text(
                        'Límite de pospones alcanzado',
                        style:
                            Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: onAlarm,
                                ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: PuntoSpacing.sm),
            PuntoTextButton(
              onPressed: _cancel,
              label: 'Cancelar alarma',
              foregroundColor: onAlarm,
              child: const Text('Cancelar alarma'),
            ),
            const SizedBox(height: PuntoSpacing.sm),
          ],
        ),
      ),
    );
  }
}

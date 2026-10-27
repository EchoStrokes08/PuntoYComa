import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/alerts/local_notification_wake_up_actuator.dart';
import '../../data/location/geolocator_location_source.dart';
import '../../data/persistence/secure_trip_repository.dart';
import '../../data/persistence/trip_history_repository.dart';
import '../../domain/entities/trip.dart';
import '../../design/design.dart';
import '../state/trip_controller.dart';
import '../view_models/view_models.dart';

/// Pantalla de alarma a pantalla completa con alto contraste.
///
/// Se muestra cuando suena la alarma sonora, con botones grandes para
/// confirmar despertar o posponer. Deliberadamente no usa el tema normal:
/// fondo naranja de alarma, tinta blanca y CTA blanco con tinta oscura.
class AlarmWakeScreen extends StatefulWidget {
  const AlarmWakeScreen({super.key, required this.trip});

  final Trip trip;

  @override
  State<AlarmWakeScreen> createState() => _AlarmWakeScreenState();
}

class _AlarmWakeScreenState extends State<AlarmWakeScreen>
    with SingleTickerProviderStateMixin {
  late TripController _controller;
  late LocalNotificationWakeUpActuator _actuator;
  late AlarmWakeViewModel _viewModel;
  late AnimationController _pulseController;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _actuator = LocalNotificationWakeUpActuator();
    _controller = TripController(
      locationSource: const GeolocatorLocationSource(),
      tripRepository: SecureTripRepository(),
      tripHistoryRepository: TripHistoryRepositoryImpl(),
      wakeUpActuator: _actuator,
      requestPermission: () async => true,
      setForegroundProtection: (_) async {},
    );
    _viewModel = AlarmWakeViewModel(
      controller: _controller,
      actuator: _actuator,
      trip: widget.trip,
    );

    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _controller.dispose();
    _pulseController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  String _formatCountdown(DateTime? wakeUpTime) {
    if (wakeUpTime == null) return '';
    final now = DateTime.now();
    final diff = wakeUpTime.difference(now);
    if (diff.isNegative) return 'ahora';
    final minutes = diff.inMinutes.remainder(60);
    final seconds = diff.inSeconds.remainder(60);
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
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
                  return Transform.scale(
                    scale: scale,
                    child: child,
                  );
                },
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: onAlarm.withValues(alpha: 0.2),
                    border: Border.all(
                      color: onAlarm,
                      width: 3,
                    ),
                  ),
                  child: Icon(
                    Icons.notifications_active_rounded,
                    size: 48,
                    color: onAlarm,
                  ),
                ),
              ),
            ),
            const SizedBox(height: PuntoSpacing.xl),
            Text(
              'Tu parada se acerca',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: onAlarm,
                    fontWeight: FontWeight.w700,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: PuntoSpacing.md),
            Text(
              'Prepara tu salida. Confirma que estás despierto.',
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
                    Icon(
                      Icons.snooze_rounded,
                      color: onAlarm,
                      size: 20,
                    ),
                    const SizedBox(width: PuntoSpacing.xs),
                    Text(
                      'Pospuesto · vuelve en '
                      '${_formatCountdown(_viewModel.snoozeWakeUpTime)}',
                      style:
                          Theme.of(context).textTheme.labelLarge?.copyWith(
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
              onPressed: _viewModel.acknowledge,
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
              PuntoOutlinedButton(
                fullWidth: true,
                onPressed: () {
                  _viewModel.setSnoozeMinutes(1);
                  _viewModel.snooze();
                },
                label: 'Posponer 1 min',
                foregroundColor: onAlarm,
                backgroundColor: PuntoColors.alarmScrim,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.snooze_rounded, size: 20),
                    SizedBox(width: PuntoSpacing.sm),
                    Flexible(
                      child: Text(
                        'Posponer 1 min',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: PuntoSpacing.sm),
              PuntoOutlinedButton(
                fullWidth: true,
                onPressed: () {
                  _viewModel.setSnoozeMinutes(5);
                  _viewModel.snooze();
                },
                label: 'Posponer 5 min',
                foregroundColor: onAlarm,
                backgroundColor: PuntoColors.alarmScrim,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.snooze_rounded, size: 20),
                    SizedBox(width: PuntoSpacing.sm),
                    Flexible(
                      child: Text(
                        'Posponer 5 min',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
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
              onPressed: () {
                _viewModel.cancel();
                context.go('/');
              },
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

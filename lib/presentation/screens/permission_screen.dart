import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../data/alerts/local_notification_wake_up_actuator.dart';
import '../../data/location/geolocator_location_source.dart';
import '../../data/persistence/secure_trip_repository.dart';
import '../../data/persistence/trip_history_repository.dart';
import '../../domain/entities/trip.dart';
import '../../design/design.dart';
import '../animations/animations.dart';
import '../state/punto_scope.dart';
import '../state/trip_controller.dart';

/// Pantalla de permiso en contexto (Fase D).
///
/// Explica por qué se necesita la ubicación justo antes de armar la alarma,
/// pide notificaciones sin bloquear y ofrece una salida clara si el permiso
/// fue denegado para siempre (abrir ajustes del sistema).
class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key, required this.trip});

  final Trip trip;

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  bool _initialized = false;
  bool _requesting = false;
  bool _locationDenied = false;
  bool _permanentlyDenied = false;

  late GeolocatorLocationSource _locationSource;
  late LocalNotificationWakeUpActuator _actuator;
  late TripController _controller;
  bool _ownsController = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final scope = PuntoScope.maybeOf(context);
    _locationSource = scope?.locationSource ?? const GeolocatorLocationSource();
    _actuator = scope?.actuator ?? LocalNotificationWakeUpActuator();
    if (scope != null) {
      _controller = scope.controller;
    } else {
      _ownsController = true;
      _controller = TripController(
        locationSource: _locationSource,
        tripRepository: SecureTripRepository(),
        tripHistoryRepository: TripHistoryRepositoryImpl(),
        wakeUpActuator: _actuator,
        requestPermission: _locationSource.ensurePermission,
        setForegroundProtection: (_) async {},
      );
    }
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  Future<void> _grantAndArm() async {
    if (_requesting) return;
    setState(() {
      _requesting = true;
      _locationDenied = false;
    });

    final granted = await _locationSource.ensurePermission();
    if (!mounted) return;
    if (!granted) {
      final permission = await Geolocator.checkPermission();
      if (!mounted) return;
      setState(() {
        _requesting = false;
        _locationDenied = true;
        _permanentlyDenied =
            permission == LocationPermission.deniedForever;
      });
      return;
    }

    // Las notificaciones son importantes, pero nunca bloquean la alarma:
    // la vibración en primer plano sigue funcionando.
    await _actuator.requestPermissions();
    final armed = await _controller.arm(widget.trip);
    if (!mounted) return;
    setState(() => _requesting = false);
    if (armed) {
      context.go('/armar');
    } else {
      setState(() => _locationDenied = true);
    }
  }

  Future<void> _openSettings() async {
    await Geolocator.openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    return PuntoScaffold(
      header: const PuntoScreenHeader(title: 'Antes de dormir'),
      bottomBar: Column(
        children: [
          PuntoButton(
            fullWidth: true,
            height: 56,
            borderRadius: PuntoBorders.lg,
            onPressed: _requesting ? null : _grantAndArm,
            label: 'Permitir y armar alarma',
            child: _requesting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  )
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shield_moon_rounded, size: 20),
                      SizedBox(width: PuntoSpacing.sm),
                      Flexible(
                        child: Text(
                          'Permitir y armar alarma',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
          ),
          if (_permanentlyDenied) ...[
            const SizedBox(height: PuntoSpacing.sm),
            PuntoOutlinedButton(
              fullWidth: true,
              onPressed: _openSettings,
              label: 'Abrir ajustes del sistema',
              child: const Text('Abrir ajustes del sistema'),
            ),
          ],
          PuntoTextButton(
            onPressed: () => context.pop(),
            label: 'Ahora no',
            child: const Text('Ahora no'),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: StaggeredReveal(
          children: [
            const SizedBox(height: PuntoSpacing.sm),
            Center(
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.primaryContainer,
                ),
                child: Icon(
                  Icons.my_location_rounded,
                  size: 42,
                  color: context.primary,
                ),
              ),
            ),
            const SizedBox(height: PuntoSpacing.lg),
            Text(
              'Tu ubicación se queda\nen tu teléfono.',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: PuntoSpacing.sm),
            Text(
              'Solo la usamos mientras la alarma está armada, para calcular '
              'cuánto falta para tu parada. Nunca se envía al servidor.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.onSurfaceVariant,
                    height: 1.5,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: PuntoSpacing.lg),
            const _PermissionCard(
              icon: Icons.location_on_rounded,
              title: 'Ubicación',
              body: 'Necesaria para despertarte antes de llegar. Puedes '
                  'revocarla cuando quieras desde los ajustes.',
            ),
            const SizedBox(height: PuntoSpacing.s12),
            const _PermissionCard(
              icon: Icons.notifications_active_rounded,
              title: 'Notificaciones',
              body: 'Permiten que la alarma te avise con la pantalla apagada. '
                  'Si las rechazas, la vibración en primer plano sigue activa.',
            ),
            const SizedBox(height: PuntoSpacing.lg),
            if (_locationDenied)
              Container(
                padding: const EdgeInsets.all(PuntoSpacing.md),
                decoration: BoxDecoration(
                  color: context.alarmContainer,
                  borderRadius: BorderRadius.circular(PuntoBorders.md),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.location_off_rounded,
                      color: context.alarm,
                      size: 20,
                    ),
                    const SizedBox(width: PuntoSpacing.sm),
                    Expanded(
                      child: Text(
                        _permanentlyDenied
                            ? 'El permiso está bloqueado. Ábrelo en los '
                                'ajustes del sistema para armar la alarma.'
                            : 'Sin ubicación no podemos calcular tu parada. '
                                'Puedes volver a intentarlo o usar el '
                                'temporizador manual desde el viaje armado.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: context.onSurface,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: PuntoSpacing.lg),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta explicativa de un permiso: ícono tintado, título y razón concreta.
class _PermissionCard extends StatelessWidget {
  const _PermissionCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return PuntoCard(
      color: context.surfaceBright,
      borderRadius: PuntoBorders.md,
      elevation: PuntoEffects.soft,
      padding: const EdgeInsets.all(PuntoSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.primaryContainer,
            ),
            child: Icon(icon, size: 22, color: context.primary),
          ),
          const SizedBox(width: PuntoSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: PuntoSpacing.xs),
                Text(
                  body,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.onSurfaceLow,
                        height: 1.4,
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

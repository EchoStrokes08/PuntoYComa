import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/alerts/local_notification_wake_up_actuator.dart';
import '../../design/design.dart';
import '../animations/animations.dart';
import '../state/punto_scope.dart';
import '../view_models/view_models.dart';

/// Pantalla de bienvenida: promesa de calma, héroe respirante y un solo CTA.
///
/// Jerarquía: marca arriba (con acceso a ajustes), héroe centrado que
/// respira, titular alineado a la izquierda, tarjeta de prueba háptica
/// secundaria y CTA principal de ancho completo al fondo.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  WelcomeViewModel? _viewModel;
  late AnimationController _fadeController;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _viewModel = WelcomeViewModel(
      actuator:
          PuntoScope.maybeOf(context)?.actuator ??
          LocalNotificationWakeUpActuator(),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _viewModel?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = _viewModel;
    if (viewModel == null) {
      return const PuntoScaffold(child: SizedBox.shrink());
    }
    return PuntoScaffold(
      header: PuntoBrandHeader(
        trailing: Semantics(
          label: 'Ajustes',
          button: true,
          child: IconButton(
            icon: const Icon(Icons.settings_outlined, size: 22),
            onPressed: () => context.push('/ajustes'),
          ),
        ),
      ),
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: _fadeController,
          curve: Curves.easeOut,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Spacer(),
            Center(
              child: BreathingScale(
                child: const _HeroMoon(),
              ),
            ),
            const SizedBox(height: PuntoSpacing.xl),
            Semantics(
              header: true,
              child: Text(
                'Descansa.\nLlegas a tiempo.',
                style: Theme.of(context).textTheme.displayLarge,
              ),
            ),
            const SizedBox(height: PuntoSpacing.s12),
            Text(
              'PuntoYcoma vigila tu trayecto y te despierta antes de tu '
              'parada, incluso cuando la señal cambia.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.onSurfaceVariant,
                    height: 1.5,
                  ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            AnimatedBuilder(
              animation: viewModel,
              builder: (context, _) => _VibrationCard(
                isPlaying: viewModel.isDemoPlaying,
                onPlay: viewModel.playHapticDemo,
              ),
            ),
            const SizedBox(height: PuntoSpacing.lg),
            PuntoButton(
              fullWidth: true,
              height: 56,
              borderRadius: PuntoBorders.lg,
              onPressed: () {
                viewModel.startFlow();
                context.push('/destino');
              },
              label: 'Crear alarma de llegada',
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_location_alt_rounded, size: 20),
                  SizedBox(width: PuntoSpacing.sm),
                  Flexible(
                    child: Text(
                      'Crear alarma de llegada',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: PuntoSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 13,
                  color: context.onSurfaceLow,
                ),
                const SizedBox(width: PuntoSpacing.xs),
                Flexible(
                  child: Text(
                    'Sin permisos hasta que armes una alarma.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.onSurfaceLow,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: PuntoSpacing.sm),
          ],
        ),
      ),
    );
  }
}

/// Héroe de bienvenida: luna en un círculo con degradado verde claro →
/// crema y un halo/anillo sutil, todo respirando lentamente.
class _HeroMoon extends StatelessWidget {
  const _HeroMoon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 168,
      height: 168,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Halo: anillo sutil que rodea el círculo del héroe.
          Container(
            width: 168,
            height: 168,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: context.primary.withValues(alpha: 0.15),
                width: 1.5,
              ),
            ),
          ),
          // Círculo con degradado suave verde claro → crema.
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  PuntoColors.primaryFixed,
                  PuntoColors.surface,
                ],
              ),
              boxShadow: PuntoEffects.floating,
            ),
            child: Center(
              child: Icon(
                Icons.nightlight_round_rounded,
                size: 56,
                color: context.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta secundaria "Prueba la vibración": superficie blanca, radio 20,
/// sombra flotante suave e ícono en círculo tintado.
class _VibrationCard extends StatelessWidget {
  const _VibrationCard({
    required this.isPlaying,
    required this.onPlay,
  });

  final bool isPlaying;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return PuntoCard(
      color: context.surfaceBright,
      borderRadius: PuntoBorders.md,
      elevation: PuntoEffects.floating,
      padding: const EdgeInsets.all(PuntoSpacing.s12 + PuntoSpacing.xs),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.primaryContainer,
            ),
            child: Icon(
              Icons.vibration_rounded,
              size: 22,
              color: context.primary,
            ),
          ),
          const SizedBox(width: PuntoSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prueba la vibración',
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: PuntoSpacing.xs),
                Text(
                  'Siente el patrón suave de despertar',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.onSurfaceLow,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: PuntoSpacing.s12),
          PuntoOutlinedButton(
            onPressed: isPlaying ? null : onPlay,
            label: 'Reproducir vibración',
            child: isPlaying
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.play_circle_rounded, size: 18),
                      SizedBox(width: PuntoSpacing.xs),
                      Text('Probar'),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

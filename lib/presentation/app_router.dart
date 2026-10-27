import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/routing/local_stop_cache.dart';
import '../domain/entities/trip.dart';
import 'screens/screens.dart';

/// Configuración de navegación nombrada con GoRouter.
///
/// Todas las rutas usan la misma transición: fundido + deslizamiento muy
/// sutil (250 ms, easeOut), calmado y consistente con la marca.
class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');

  static GoRouter createRouter() {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/',
      debugLogDiagnostics: false,
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) =>
              _fadeSlide(state, const WelcomeScreen()),
        ),
        GoRoute(
          path: '/destino',
          pageBuilder: (context, state) => _fadeSlide(
            state,
            DestinationScreen(editing: state.extra == true),
          ),
        ),
        GoRoute(
          path: '/preparacion',
          pageBuilder: (context, state) {
            return _fadeSlide(
              state,
              PreparationScreen(stop: _stopFromExtra(state.extra)),
            );
          },
        ),
        GoRoute(
          path: '/permisos',
          pageBuilder: (context, state) {
            final trip = state.extra as Trip?;
            if (trip == null) {
              return _fadeSlide(
                state,
                const _MissingTripScreen(
                  message: 'No hay viaje por armar.',
                ),
              );
            }
            return _fadeSlide(state, PermissionScreen(trip: trip));
          },
        ),
        GoRoute(
          path: '/armar',
          pageBuilder: (context, state) =>
              _fadeSlide(state, ArmedTripScreen(trip: state.extra as Trip?)),
        ),
        GoRoute(
          path: '/alarma',
          pageBuilder: (context, state) {
            final trip = state.extra as Trip?;
            if (trip == null) {
              return _fadeSlide(
                state,
                const _MissingTripScreen(message: 'No hay viaje activo.'),
              );
            }
            return _fadeSlide(state, AlarmWakeScreen(trip: trip));
          },
        ),
        GoRoute(
          path: '/historial',
          pageBuilder: (context, state) =>
              _fadeSlide(state, const HistoryScreen()),
        ),
        GoRoute(
          path: '/ajustes',
          pageBuilder: (context, state) =>
              _fadeSlide(state, const SettingsScreen()),
        ),
      ],
    );
  }

  /// Acepta tanto una parada como un viaje guardado (historial). Antes el
  /// historial enviaba un [Trip] y la ruta lo casteaba a [CachedStop], lo que
  /// rompía al repetir una alarma.
  static CachedStop _stopFromExtra(Object? extra) {
    if (extra is CachedStop) return extra;
    if (extra is Trip) {
      return CachedStop(
        id: extra.id,
        name: 'Destino guardado',
        latitude: extra.destination.latitude,
        longitude: extra.destination.longitude,
        mode: extra.mode,
        routeId: '${extra.alertLeadTime.inMinutes} min',
      );
    }
    return const CachedStop(
      id: 'default',
      name: 'Calle 76',
      latitude: 4.6680,
      longitude: -74.0519,
      mode: TransportMode.metro,
    );
  }

  /// Transición de página de PuntoYcoma: fundido + slide leve de 250 ms.
  static CustomTransitionPage<void> _fadeSlide(
    GoRouterState state,
    Widget child,
  ) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      transitionDuration: const Duration(milliseconds: 250),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved =
            CurvedAnimation(parent: animation, curve: Curves.easeOut);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.015),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Estado seguro para rutas que requieren un viaje en `extra`.
class _MissingTripScreen extends StatelessWidget {
  const _MissingTripScreen({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 40),
            const SizedBox(height: 12),
            Text(message),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go('/'),
              child: const Text('Volver al inicio'),
            ),
          ],
        ),
      ),
    );
  }
}

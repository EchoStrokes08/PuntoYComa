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
          pageBuilder: (context, state) =>
              _fadeSlide(state, const DestinationScreen()),
        ),
        GoRoute(
          path: '/preparacion',
          pageBuilder: (context, state) {
            final stop = state.extra as CachedStop?;
            return _fadeSlide(
              state,
              PreparationScreen(
                stop: stop ??
                    CachedStop(
                      id: 'default',
                      name: 'Calle 76',
                      latitude: 4.6680,
                      longitude: -74.0519,
                      mode: TransportMode.metro,
                    ),
              ),
            );
          },
        ),
        GoRoute(
          path: '/armar',
          pageBuilder: (context, state) =>
              _fadeSlide(state, const ArmedTripScreen()),
        ),
        GoRoute(
          path: '/alarma',
          pageBuilder: (context, state) {
            final trip = state.extra as Trip?;
            if (trip == null) {
              return _fadeSlide(
                state,
                const Scaffold(
                  body: Center(child: Text('No hay viaje activo')),
                ),
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

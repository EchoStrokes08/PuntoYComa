import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:punto_y_coma/domain/entities/trip.dart';
import 'package:punto_y_coma/domain/services/wake_up_policy.dart';

import 'helpers/test_app.dart';

/// Fase E: Prueba de integración E2E del viaje completo.
///
/// Flujo simulado:
/// 1. Pantalla de bienvenida → tocar "Crear alarma de llegada"
/// 2. Pantalla de destino → seleccionar "Calle 76" → "Confirmar destino"
/// 3. Pantalla de preparación → "Armar alarma"
/// 4. Pantalla de permisos → "Permitir y armar alarma"
/// 5. Pantalla armada (radar) → emitir fixes GPS (2600m → 300m)
/// 6. Navegar a pantalla de alarma → tocar "1 min" (posponer) → "Ya desperté"
/// 7. Verificar regreso a bienvenida con mensaje "Descansa.\nLlegas a tiempo."
/// 8. Verificar que el viaje se guardó en el historial (FakeTripHistoryRepository)

void main() {
  testWidgets('Viaje completo E2E: bienvenida → destino → preparación → '
      'permisos → armar → alarma → posponer → despertar → historial',
      (tester) async {
    // ── Preparación ──────────────────────────────────────────────────────
    final bundle = TestBundle(seedStops: true);
    await bundle.seedStops();
    await pumpApp(tester, bundle);

    // ── 1. Bienvenida → Destino ──────────────────────────────────────────
    await tester.tap(find.text('Crear alarma de llegada'));
    await pumpRoute(tester);
    expect(find.text('¿Dónde te bajas?'), findsOneWidget);

    // ── 2. Destino → elegir parada → Preparación ─────────────────────────
    await tester.tap(find.text('Calle 76'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Confirmar destino'), findsOneWidget);

    await tester.tap(find.text('Confirmar destino'));
    await pumpRoute(tester);
    expect(find.text('Prepara tu descanso'), findsOneWidget);

    // ── 3. Preparación → Armar alarma ────────────────────────────────────
    await tester.tap(find.text('Armar alarma'));
    await pumpRoute(tester);

    // ── 4. Permisos → Permitir y armar ───────────────────────────────────
    expect(find.text('Antes de dormir'), findsOneWidget);
    await tester.tap(find.text('Permitir y armar alarma'));
    await pumpRoute(tester);

    // El viaje debe quedar armado
    expect(bundle.controller.isArmed, isTrue);
    expect(bundle.actuator.permissionRequests, 1);
    expect(find.text('Vigilando la ruta'), findsOneWidget);

    // ── 5. Radar → emitir fixes GPS (lejos → cerca) ──────────────────────
    // Fix a 2600 m (fase monitoring)
    bundle.clockValue = bundle.clockValue.add(const Duration(minutes: 1));
    bundle.locationSource.emit(
      fixAtMetersNorth(2600, at: bundle.clockValue),
    );
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Vigilando la ruta'), findsOneWidget);

    // Fix a 1000 m (fase gentleHaptic - vibración suave)
    bundle.clockValue = bundle.clockValue.add(const Duration(minutes: 1));
    bundle.locationSource.emit(
      fixAtMetersNorth(1000, at: bundle.clockValue),
    );
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Vibración suave activa'), findsOneWidget);

    // ── 6. Navegar a pantalla de alarma → posponer → despertar ───────────
    bundle.router.go('/alarma', extra: bundle.controller.activeTrip);
    await pumpRoute(tester);
    expect(find.text('Tu parada se acerca'), findsOneWidget);

    // Posponer 1 min
    await tester.tap(find.text('1 min'));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Alarma pospuesta'), findsOneWidget);
    expect(find.textContaining('Pospones restantes: 2'), findsWidgets);

    // Ya desperté → completa el viaje y vuelve al inicio
    await tester.tap(find.text('Ya desperté'));
    await pumpRoute(tester);

    expect(bundle.controller.isArmed, isFalse);
    expect(find.text('Descansa.\nLlegas a tiempo.'), findsOneWidget);

    // ── 7. Verificar historial ───────────────────────────────────────────
    final recents = await bundle.historyRepository.getRecents();
    expect(recents, isNotEmpty);
    expect(recents.first.destination.latitude, closeTo(4.6680, 0.001));
    expect(recents.first.status, TripStatus.completed);
    expect(recents.first.alertLeadTime, const Duration(minutes: 4));

    // Limpieza para no dejar temporizadores en la zona FakeAsync
    await cancelTrip(tester, bundle);
  });

  testWidgets('Viaje completo con temporizador manual (sin GPS)',
      (tester) async {
    final bundle = TestBundle(seedStops: true);
    await bundle.seedStops();
    await pumpApp(tester, bundle);

    // Flujo rápido hasta armar
    await tester.tap(find.text('Crear alarma de llegada'));
    await pumpRoute(tester);

    await tester.tap(find.text('Calle 76'));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.text('Confirmar destino'));
    await pumpRoute(tester);

    await tester.tap(find.text('Armar alarma'));
    await pumpRoute(tester);

    await tester.tap(find.text('Permitir y armar alarma'));
    await pumpRoute(tester);
    expect(bundle.controller.isArmed, isTrue);

    // En lugar de GPS, usar temporizador manual de 5 min
    await tester.tap(find.text('Temporizador'));
    await pumpRoute(tester);

    await tester.tap(find.text('5 min'));
    await pumpRoute(tester);

    // El temporizador manual debe aparecer en el radar
    expect(find.textContaining('Temporizador manual · '), findsOneWidget);

    // Avanzar el reloj 2 minutos → debe disparar la alarma manual
    bundle.clockValue = bundle.clockValue.add(const Duration(minutes: 2));
    await tester.pump(const Duration(milliseconds: 500));

    // Navegar a alarma y despertar
    bundle.router.go('/alarma', extra: bundle.controller.activeTrip);
    await pumpRoute(tester);
    expect(find.text('Tu parada se acerca'), findsOneWidget);

    await tester.tap(find.text('Ya desperté'));
    await pumpRoute(tester);

    expect(bundle.controller.isArmed, isFalse);
    expect(find.text('Descansa.\nLlegas a tiempo.'), findsOneWidget);

    // Verificar historial
    final recents = await bundle.historyRepository.getRecents();
    expect(recents, isNotEmpty);
    expect(recents.first.status, TripStatus.completed);

    await cancelTrip(tester, bundle);
  });
}
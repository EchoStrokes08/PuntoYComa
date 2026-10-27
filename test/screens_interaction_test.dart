import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:punto_y_coma/domain/entities/trip.dart';
import 'package:punto_y_coma/domain/services/wake_up_policy.dart';

import 'helpers/test_app.dart';

/// Fase E: pruebas widget de interacción, al menos una por pantalla.
///
/// Cada prueba monta la app real (pantallas + enrutador + controlador) con
/// dependencias de plataforma falsas y verifica un comportamiento de usuario
/// concreto.
///
/// Nota sobre los finders: aquí se tapan por texto/ícono visible y no por
/// etiqueta de semántica. En el entorno de pruebas de la app los taps por
/// etiqueta de semántica no llegan al botón (aunque la estructura es
/// idéntica al toy de control que sí funciona); el árbol semántico se
/// verifica por separado en `accessibility_test.dart` con las guías
/// (`labeledTapTargetGuideline`, contraste) y por captura de semántica.
void main() {
  group('WelcomeScreen', () {
    testWidgets('el botón "Probar" reproduce el patrón háptico de demo',
        (tester) async {
      final bundle = TestBundle();
      await pumpApp(tester, bundle);

      await tester.tap(find.text('Probar'));
      await tester.pump(const Duration(milliseconds: 120));

      expect(bundle.actuator.testPatterns, 1);
      expect(bundle.actuator.stages, contains(WakeUpStage.gentleHaptic));
    });

    testWidgets('el CTA de crear alarma navega a la pantalla de destino',
        (tester) async {
      final bundle = TestBundle();
      await pumpApp(tester, bundle);

      await tester.tap(find.text('Crear alarma de llegada'));
      await pumpRoute(tester);

      expect(find.text('¿Dónde te bajas?'), findsOneWidget);
    });
  });

  group('DestinationScreen', () {
    testWidgets('una búsqueda sin coincidencias muestra el estado vacío',
        (tester) async {
      final bundle = TestBundle();
      await pumpApp(tester, bundle);

      await tester.tap(find.text('Crear alarma de llegada'));
      await pumpRoute(tester);

      await tester.enterText(find.byType(TextField), 'en ninguna parte');
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('No se encontraron paradas'), findsOneWidget);
    });

    testWidgets('elegir una parada habilita el CTA y navega a preparación',
        (tester) async {
      final bundle = TestBundle(seedStops: true);
      await bundle.seedStops();
      await pumpApp(tester, bundle);

      await tester.tap(find.text('Crear alarma de llegada'));
      await pumpRoute(tester);

      // Antes de elegir: CTA deshabilitado con texto de invitación.
      expect(find.text('Elige una parada'), findsOneWidget);

      await tester.tap(find.text('Calle 76'));
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Confirmar destino'), findsOneWidget);

      await tester.tap(find.text('Confirmar destino'));
      await pumpRoute(tester);

      expect(find.text('Prepara tu descanso'), findsOneWidget);
    });
  });

  group('PreparationScreen', () {
    testWidgets('vibración y notificación de prueba llegan al actuador',
        (tester) async {
      final bundle = TestBundle();
      await pumpApp(tester, bundle);

      bundle.router.go('/preparacion', extra: sampleStop());
      await pumpRoute(tester);

      // En pantalla hay dos botones "Probar": vibración (izquierda) y
      // notificación (derecha), en ese orden.
      await tester.tap(find.text('Probar').first);
      await tester.pump(const Duration(milliseconds: 160));
      expect(bundle.actuator.testPatterns, 1);

      await tester.tap(find.text('Probar').last);
      await tester.pump(const Duration(milliseconds: 160));
      expect(bundle.actuator.testNotifications, 1);
    });

    testWidgets('el interruptor de sonido cambia en el view model',
        (tester) async {
      final bundle = TestBundle();
      await pumpApp(tester, bundle);

      bundle.router.go('/preparacion', extra: sampleStop());
      await pumpRoute(tester);

      // El interruptor es el último hijo del StaggeredReveal (retraso de
      // 720 ms + 600 ms de animación): hay que bombear más allá de los
      // 600 ms de pumpRoute para que sea visible y tocable.
      await tester.pump(const Duration(milliseconds: 900));

      await tester.tap(find.text('Sonido al final'));
      await tester.pump(const Duration(milliseconds: 250));

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is SwitchListTile &&
              widget.value == true &&
              widget.title is Text &&
              (widget.title! as Text).data == 'Sonido al final',
        ),
        findsOneWidget,
      );
    });
  });

  group('PermissionScreen', () {
    testWidgets('con permiso concedido arma la alarma y navega al radar',
        (tester) async {
      final bundle = TestBundle();
      await pumpApp(tester, bundle);

      bundle.router.go('/permisos', extra: draftedTrip());
      await pumpRoute(tester);

      await tester.tap(find.text('Permitir y armar alarma'));
      await pumpRoute(tester);

      // Las notificaciones se pidieron sin bloquear y el viaje quedó armado.
      expect(bundle.actuator.permissionRequests, 1);
      expect(bundle.controller.isArmed, isTrue);
      expect(find.text('Vigilando la ruta'), findsOneWidget);

      // Cancelar para no dejar temporizadores del viaje pendientes al
      // terminar la prueba.
      await cancelTrip(tester, bundle);
    });

    testWidgets('sin permiso muestra explicación y no arma nada',
        (tester) async {
      final bundle = TestBundle();
      bundle.locationSource.permissionGranted = false;
      await pumpApp(tester, bundle);

      bundle.router.go('/permisos', extra: draftedTrip());
      await pumpRoute(tester);

      await tester.tap(find.text('Permitir y armar alarma'));
      await pumpRoute(tester);

      expect(bundle.controller.isArmed, isFalse);
      expect(
        find.textContaining('Sin ubicación no podemos calcular'),
        findsOneWidget,
      );
    });
  });

  group('ArmedTripScreen', () {
    testWidgets('los fixes de ubicación escalan la etapa en el radar',
        (tester) async {
      final bundle = TestBundle();
      await pumpApp(tester, bundle);

      bundle.router.go('/armar', extra: draftedTrip());
      await pumpRoute(tester);
      expect(find.text('Vigilando la ruta'), findsOneWidget);

      bundle.locationSource.emit(
        fixAtMetersNorth(2600, at: bundle.clockValue),
      );
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Vigilando la ruta'), findsOneWidget);

      bundle.clockValue = bundle.clockValue.add(const Duration(minutes: 1));
      // Radio de alerta dinámico con margen de 4 min y 6 m/s ≈ 1540 m; la
      // banda de vibración suave queda entre 45% del radio (~690 m) y el
      // radio completo, así que un fix a 1000 m escala a esa etapa.
      bundle.locationSource.emit(
        fixAtMetersNorth(1000, at: bundle.clockValue),
      );
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Vibración suave activa'), findsOneWidget);

      await cancelTrip(tester, bundle);
    });

    testWidgets('editar el margen se refleja en el viaje armado',
        (tester) async {
      final bundle = TestBundle();
      await pumpApp(tester, bundle);

      bundle.router.go('/armar', extra: draftedTrip());
      await pumpRoute(tester);

      await tester.tap(find.text('Editar'));
      await pumpRoute(tester);

      final chip8 = find.widgetWithText(ChoiceChip, '8 min');
      expect(chip8, findsOneWidget);
      await tester.tap(chip8);
      await tester.pump(const Duration(milliseconds: 250));

      await tester.tap(find.text('Guardar cambios'));
      await pumpRoute(tester);

      expect(
        bundle.controller.activeTrip?.alertLeadTime,
        const Duration(minutes: 8),
      );
      await cancelTrip(tester, bundle);
    });

    testWidgets('el temporizador manual queda visible en el radar',
        (tester) async {
      final bundle = TestBundle();
      await pumpApp(tester, bundle);

      bundle.router.go('/armar', extra: draftedTrip());
      await pumpRoute(tester);

      await tester.tap(find.text('Temporizador'));
      await pumpRoute(tester);

      await tester.tap(find.text('15 min'));
      await pumpRoute(tester);

      expect(find.textContaining('Temporizador manual · '), findsOneWidget);

      // Cancelar el temporizador desde la tarjeta (ícono de cierre).
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.textContaining('Temporizador manual · '), findsNothing);
      await cancelTrip(tester, bundle);
    });
  });

  group('AlarmWakeScreen', () {
    testWidgets(
        'posponer reprograma la alarma y "Ya desperté" completa y vuelve al inicio',
        (tester) async {
      final bundle = TestBundle();
      await pumpApp(tester, bundle);
      await bundle.controller.arm(draftedTrip());

      bundle.router.go('/alarma', extra: bundle.controller.activeTrip);
      await pumpRoute(tester);
      expect(find.text('Tu parada se acerca'), findsOneWidget);

      // Posponer: el estado vive en el controlador compartido.
      await tester.tap(find.text('1 min'));
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Alarma pospuesta'), findsOneWidget);
      // El contador aparece en el cuerpo y en la semántica del botón.
      expect(find.textContaining('Pospones restantes: 2'), findsWidgets);

      // Ya desperté: cierra el viaje y regresa a la pantalla de bienvenida.
      await tester.tap(find.text('Ya desperté'));
      await pumpRoute(tester);

      expect(bundle.controller.isArmed, isFalse);
      expect(find.text('Descansa.\nLlegas a tiempo.'), findsOneWidget);
    });

    testWidgets(
        'al agotar los 3 pospones desaparecen los botones de posponer',
        (tester) async {
      final bundle = TestBundle();
      await pumpApp(tester, bundle);
      await bundle.controller.arm(draftedTrip());

      bundle.router.go('/alarma', extra: bundle.controller.activeTrip);
      await pumpRoute(tester);

      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('1 min'));
        await tester.pump(const Duration(milliseconds: 300));
      }

      expect(bundle.controller.canSnooze, isFalse);
      expect(find.text('1 min'), findsNothing);
      expect(find.text('Límite de pospones alcanzado'), findsOneWidget);
      await cancelTrip(tester, bundle);
    });
  });

  group('HistoryScreen', () {
    testWidgets('sin viajes muestra el estado vacío ilustrado',
        (tester) async {
      final bundle = TestBundle();
      await pumpApp(tester, bundle);

      bundle.router.go('/historial');
      await pumpRoute(tester);

      expect(find.text('Aún no hay viajes'), findsOneWidget);
    });

    testWidgets('lista recientes y alterna favorito al tocar la estrella',
        (tester) async {
      final bundle = TestBundle();
      await bundle.historyRepository.saveRecent(
        Trip(
          id: 'trip-h1',
          destination: kDestination,
          mode: TransportMode.metro,
          status: TripStatus.completed,
          alertLeadTime: const Duration(minutes: 4),
        ),
      );
      await pumpApp(tester, bundle);

      bundle.router.go('/historial');
      await pumpRoute(tester);

      expect(find.text('Recientes'), findsOneWidget);
      expect(
        find.byIcon(Icons.star_border_rounded),
        findsOneWidget,
      );

      // La estrella alterna el favorito en el repositorio compartido.
      final star = find.byIcon(Icons.star_border_rounded);
      final starCenter = tester.getCenter(star);
      await tester.tapAt(starCenter);
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
      expect(find.text('Favoritos'), findsOneWidget);
    });
  });

  group('SettingsScreen', () {
    testWidgets('los interruptores cambian al tocarlos', (tester) async {
      final bundle = TestBundle();
      await pumpApp(tester, bundle);

      bundle.router.go('/ajustes');
      await pumpRoute(tester);

      // Interruptores por defecto encendidos: tras tocar quedan apagados.
      final switches = find.byType(Switch);
      expect(switches, findsNWidgets(2));
      await tester.tap(switches.first);
      await tester.pump(const Duration(milliseconds: 220));

      expect(
        tester
            .widget<Switch>(find.byType(Switch).first)
            .value,
        isFalse,
      );
    });

    testWidgets('el slider ajusta la fuerza de vibración', (tester) async {
      final bundle = TestBundle();
      await pumpApp(tester, bundle);

      bundle.router.go('/ajustes');
      await pumpRoute(tester);

      expect(find.text('1.0'), findsOneWidget);
      await tester.drag(find.byType(Slider).first, const Offset(-120, 0));
      await tester.pump(const Duration(milliseconds: 220));

      expect(find.text('1.0'), findsNothing);
    });
  });
}

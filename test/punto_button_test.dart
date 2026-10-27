import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:punto_y_coma/design/design.dart';

void main() {
  testWidgets('PuntoButton dentro de un Row no lanza excepción de layout',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              PuntoButton(
                onPressed: () {},
                label: 'Botón en Row',
                child: const Text('Botón en Row'),
              ),
            ],
          ),
        ),
      ),
    );

    // Verificar que el botón se renderizó sin error de layout
    expect(find.text('Botón en Row'), findsOneWidget);
  });

  testWidgets('PuntoButton con fullWidth: true dentro de una Column no lanza '
      'excepción de layout', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              PuntoButton(
                fullWidth: true,
                onPressed: () {},
                label: 'Botón ancho completo',
                child: const Text('Botón ancho completo'),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Botón ancho completo'), findsOneWidget);
  });

  testWidgets('PuntoOutlinedButton dentro de un Row no lanza excepción de '
      'layout', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              PuntoOutlinedButton(
                onPressed: () {},
                label: 'Outlined en Row',
                child: const Text('Outlined en Row'),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Outlined en Row'), findsOneWidget);
  });

  testWidgets('PuntoOutlinedButton con fullWidth: true dentro de una Column '
      'no lanza excepción de layout', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              PuntoOutlinedButton(
                fullWidth: true,
                onPressed: () {},
                label: 'Outlined ancho completo',
                child: const Text('Outlined ancho completo'),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Outlined ancho completo'), findsOneWidget);
  });

  testWidgets('PuntoButton dentro de PuntoCard con AnimatedBuilder (como en '
      'WelcomeScreen) no lanza excepción de layout', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PuntoCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('Texto'),
                const Spacer(),
                PuntoButton(
                  onPressed: () {},
                  label: 'Probar',
                  child: const Text('Probar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Probar'), findsOneWidget);
  });
}

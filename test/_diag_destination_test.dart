import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:punto_y_coma/design/design.dart';

import 'helpers/test_app.dart';

void _log(String message) {
  File(
    'C:\\Users\\oscar\\AppData\\Local\\Temp\\opencode\\breadcrumbs.log',
  ).writeAsStringSync('$message\n', mode: FileMode.append);
}

void main() {
  setUpAll(() {
    _log('── RUN ──');
  });

  testWidgets('replica del flujo sin permiso', (tester) async {
    final bundle = TestBundle();
    bundle.locationSource.permissionGranted = false;
    _log('STEP: pumpApp');
    await pumpApp(tester, bundle);

    bundle.router.go('/permisos', extra: draftedTrip());
    await pumpRoute(tester);
    _log('STEP: pumpRoute hecho');

    final btn = find.text('Permitir y armar alarma');
    _log('BTN=${tester.widgetList(btn).length}');
    final onPressed = tester
        .widget<PuntoButton>(
          find.ancestor(of: btn, matching: find.byType(PuntoButton)).first,
        )
        .onPressed;
    _log('onPressed!=null → ${onPressed != null}');

    await tester.tap(btn);
    _log('STEP: tapped');
    await pumpRoute(tester);
    _log('STEP: pumpRoute tras tap');

    _log('locationRequests=${bundle.locationSource.permissionRequests}');
    _log('isArmed=${bundle.controller.isArmed}');
    final denial = find.textContaining('Sin ubicación no podemos calcular');
    _log('denial=${tester.widgetList(denial).length}');
    final spinner = find.byType(CircularProgressIndicator);
    _log('spinners=${tester.widgetList(spinner).length}');
    await cancelTrip(tester, bundle);
    _log('STEP: done');
  });
}
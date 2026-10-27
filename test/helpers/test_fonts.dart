import 'package:flutter/services.dart';

bool _fontsLoaded = false;

/// Registra las fuentes reales de la app en el motor de tests.
///
/// Por defecto, los widget tests miden el texto con la fuente Ahem (cada
/// glifo ocupa `fontSize` de ancho), lo que infla los anchos de texto y
/// produce desbordamientos falsos. Registrando Plus Jakarta Sans, los tests
/// de humo miden el layout con las métricas reales de producción.
Future<void> loadAppFonts() async {
  if (_fontsLoaded) return;
  _fontsLoaded = true;
  final loader = FontLoader('PlusJakartaSans')
    ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans_wght.ttf'))
    ..addFont(
      rootBundle.load('assets/fonts/PlusJakartaSans_Italic_wght.ttf'),
    );
  await loader.load();
}

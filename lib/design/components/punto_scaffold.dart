import 'package:flutter/material.dart';

import '../../design/tokens/tokens.dart';

/// Scaffold base de PuntoYcoma.
///
/// Garantiza tres invariantes de layout en TODAS las pantallas:
///
/// 1. **Fondo y SafeArea** consistentes con el tema.
/// 2. **Padding horizontal de 24** en todo el contenido (márgenes laterales
///    que antes faltaban: logo, títulos y botones pegados al borde).
/// 3. [child] vive en un área con **altura acotada** ([Expanded]): los
///    `Column` con `Spacer`/`Expanded` dentro ya no reciben altura infinita.
///    Esto elimina de raíz el error
///    "RenderFlex children have non-zero flex but incoming height constraints
///    are unbounded".
///
/// [header] se muestra fijo arriba (marca o barra con botón atrás + título).
/// [bottomBar] se fija abajo dentro de SafeArea (ej. CTA de confirmación).
class PuntoScaffold extends StatelessWidget {
  const PuntoScaffold({
    super.key,
    required this.child,
    this.header,
    this.bottomBar,
    this.backgroundColor,
  });

  /// Contenido principal. Recibe altura acotada: puede ser un `Column` con
  /// `Spacer`/`Expanded` o un `SingleChildScrollView`.
  final Widget child;

  /// Cabecera fija (opcional) con padding horizontal de 24.
  final Widget? header;

  /// Barra fija inferior (opcional) dentro de SafeArea, con padding 24.
  final Widget? bottomBar;

  /// Fondo del Scaffold. Por defecto, la superficie del tema.
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final background =
        backgroundColor ?? Theme.of(context).colorScheme.surface;

    return Scaffold(
      backgroundColor: background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (header != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: PuntoSpacing.pagePadding,
                ),
                child: header!,
              ),
            Expanded(
              // Área de altura acotada: aquí es seguro usar Column con
              // Expanded/Spacer, o SingleChildScrollView si el contenido
              // puede exceder la pantalla.
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: PuntoSpacing.pagePadding,
                ),
                child: child,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: bottomBar == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  PuntoSpacing.pagePadding,
                  PuntoSpacing.sm,
                  PuntoSpacing.pagePadding,
                  PuntoSpacing.md,
                ),
                child: bottomBar,
              ),
            ),
    );
  }
}

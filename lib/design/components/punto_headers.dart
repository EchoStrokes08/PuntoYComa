import 'package:flutter/material.dart';

import '../../design/tokens/tokens.dart';

/// Marca de PuntoYcoma: punto verde + nombre.
///
/// Usada como cabecera de marca en todas las pantallas para consistencia
/// (antes cada pantalla tenía su propia copia privada).
class PuntoBrandMark extends StatelessWidget {
  const PuntoBrandMark({
    super.key,
    this.dotColor,
    this.textColor,
  });

  /// Color del punto. Por defecto, el primario de la marca.
  final Color? dotColor;

  /// Color del nombre. Por defecto, la tinta principal del tema.
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'PuntoYcoma',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: dotColor ?? scheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: PuntoSpacing.sm),
          Text(
            'PuntoYcoma',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: textColor ?? scheme.onSurface,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                ),
          ),
        ],
      ),
    );
  }
}

/// Cabecera de marca: logo a la izquierda y acciones opcionales a la derecha.
///
/// Usada en pantallas raíz (bienvenida, viaje armado).
class PuntoBrandHeader extends StatelessWidget {
  const PuntoBrandHeader({
    super.key,
    this.trailing,
    this.centered = false,
    this.dotColor,
    this.textColor,
  });

  /// Acción opcional a la derecha (ej. ícono de ajustes).
  final Widget? trailing;

  /// Centra la marca (usado en la pantalla de alarma a pantalla completa).
  final bool centered;

  final Color? dotColor;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final mark = PuntoBrandMark(dotColor: dotColor, textColor: textColor);
    return Padding(
      padding: const EdgeInsets.only(
        top: PuntoSpacing.lg,
        bottom: PuntoSpacing.sm,
      ),
      child: centered
          ? Center(child: mark)
          : Row(
              children: [
                mark,
                const Spacer(),
                if (trailing != null) trailing!,
              ],
            ),
    );
  }
}

/// Barra superior de pantalla con botón atrás y título.
///
/// Usada en pantallas apiladas (destino, preparación, historial, ajustes).
/// El botón atrás tiene touch target de 48×48 y semántica de "Volver".
class PuntoScreenHeader extends StatelessWidget {
  const PuntoScreenHeader({
    super.key,
    required this.title,
    this.trailing,
    this.showBackButton = true,
  });

  final String title;
  final Widget? trailing;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          if (showBackButton)
            Semantics(
              label: 'Volver',
              button: true,
              enabled: canPop,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, size: 22),
                onPressed: canPop ? Navigator.of(context).maybePop : null,
              ),
            ),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

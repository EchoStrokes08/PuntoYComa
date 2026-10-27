import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../data/routing/local_stop_cache.dart';
import '../../domain/entities/trip.dart';
import '../../design/design.dart';
import '../state/punto_scope.dart';
import '../view_models/view_models.dart';
import '../widgets/widgets.dart';

/// Pantalla de destino: mapa interactivo, búsqueda y selección de parada.
///
/// Flujo: el usuario elige una parada (mapa, búsqueda o listas) y confirma
/// con el botón fijo inferior, que permanece deshabilitado hasta que haya
/// una selección.
///
/// Con [editing] en true se usa para cambiar el destino de un viaje ya
/// armado: confirma sobre el controlador compartido y vuelve al radar sin
/// cancelar la vigilancia.
class DestinationScreen extends StatefulWidget {
  const DestinationScreen({super.key, this.editing = false});

  final bool editing;

  @override
  State<DestinationScreen> createState() => _DestinationScreenState();
}

class _DestinationScreenState extends State<DestinationScreen> {
  DestinationViewModel? _viewModel;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_viewModel != null) return;
    // Caché compartido con el controlador: una sola instancia de paradas
    // sirve a la pantalla de destino y a la alarma (estado único de la app).
    _viewModel = DestinationViewModel(
      stopCache:
          PuntoScope.maybeOf(context)?.controller.stopCache ??
          LocalStopCache(),
    );
    _viewModel!.loadRecents();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _viewModel?.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _viewModel?.searchStops(_searchController.text);
  }

  void _selectStop(CachedStop stop) {
    _viewModel?.selectStop(stop);
  }

  Future<void> _confirmSelection() async {
    final viewModel = _viewModel;
    if (viewModel == null) return;
    final stop = viewModel.selectedStop;
    if (stop == null) return;
    await viewModel.saveRecent(stop);
    if (!mounted) return;
    if (widget.editing) {
      final scope = PuntoScope.maybeOf(context);
      await scope?.controller.editActiveTrip(
        destination: GeoPoint(stop.latitude, stop.longitude),
        mode: stop.mode,
      );
      if (mounted) context.pop();
      return;
    }
    context.push('/preparacion', extra: stop);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = _viewModel;
    if (viewModel == null) {
      return const PuntoScaffold(child: SizedBox.shrink());
    }
    return PuntoScaffold(
      header: PuntoScreenHeader(
        title: widget.editing ? 'Cambiar destino' : '¿Dónde te bajas?',
      ),
      bottomBar: AnimatedBuilder(
        animation: viewModel,
        builder: (context, _) {
          final hasSelection = viewModel.selectedStop != null;
          final cta = widget.editing
              ? 'Actualizar destino'
              : (hasSelection ? 'Confirmar destino' : 'Elige una parada');
          return PuntoButton(
            fullWidth: true,
            height: 56,
            borderRadius: PuntoBorders.lg,
            onPressed: hasSelection ? _confirmSelection : null,
            label: cta,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded, size: 20),
                const SizedBox(width: PuntoSpacing.sm),
                Flexible(
                  child: Text(
                    cta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
      ),
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: AnimatedBuilder(
          animation: viewModel,
          builder: (context, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: PuntoSpacing.sm),

              // ── Mapa ────────────────────────────────────────────────
              PuntoMapView(
                stops: viewModel.recentStops,
                selectedStop: viewModel.selectedStop,
                height: 220,
                onStopTapped: (stop) {
                  _selectStop(stop);
                  _searchController.clear();
                  viewModel.clearSearch();
                  _searchFocus.unfocus();
                },
                initialPosition: viewModel.recentStops.isNotEmpty
                    ? LatLng(
                        viewModel.recentStops.first.latitude,
                        viewModel.recentStops.first.longitude,
                      )
                    : null,
              ),
              const SizedBox(height: PuntoSpacing.lg),

              // ── Búsqueda ──────────────────────────────────────────────
              Semantics(
                label: 'Buscar paradas',
                textField: true,
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocus,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Buscar parada o dirección',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchController.clear();
                              viewModel.clearSearch();
                            },
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: PuntoSpacing.lg),

              // ── Contenido según búsqueda ─────────────────────────────
              if (viewModel.searchQuery.isNotEmpty) ...[
                const _SectionTitle('Resultados'),
                if (viewModel.searchResults.isEmpty)
                  const _EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'No se encontraron paradas',
                    subtitle: 'Prueba con otro nombre o número de ruta.',
                  )
                else
                  ...viewModel.searchResults.map(
                    (stop) => _StopCard(
                      stop: stop,
                      selected: viewModel.selectedStop?.id == stop.id,
                      onTap: () => _selectStop(stop),
                    ),
                  ),
              ] else ...[
                // ── Paradas recientes ───────────────────────────────────
                if (viewModel.recentStops.isNotEmpty) ...[
                  const _SectionTitle('Recientes'),
                  ...viewModel.recentStops.map(
                    (stop) => _StopCard(
                      stop: stop,
                      selected: viewModel.selectedStop?.id == stop.id,
                      onTap: () => _selectStop(stop),
                    ),
                  ),
                  const SizedBox(height: PuntoSpacing.lg),
                ],

                // ── Paradas cercanas ────────────────────────────────────
                const _SectionTitle('Cerca de ti'),
                if (viewModel.isLoading)
                  const _SkeletonList()
                else if (viewModel.nearbyStops.isEmpty)
                  const _EmptyState(
                    icon: Icons.location_off_rounded,
                    title: 'Sin paradas cercanas guardadas',
                    subtitle: 'Tus paradas confirmadas aparecerán aquí '
                        'automáticamente.',
                  )
                else
                  ...viewModel.nearbyStops.map(
                    (stop) => _StopCard(
                      stop: stop,
                      selected: viewModel.selectedStop?.id == stop.id,
                      onTap: () => _selectStop(stop),
                    ),
                  ),
              ],
              const SizedBox(height: PuntoSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

/// Título de sección consistente (titleSmall, tinta secundaria).
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: PuntoSpacing.sm,
        bottom: PuntoSpacing.s12,
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: context.onSurfaceLow,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
      ),
    );
  }
}

/// Tarjeta de parada: ícono de ubicación en círculo tintado, nombre,
/// subtítulo y estado de selección claro. Separación de 12 entre tarjetas.
class _StopCard extends StatelessWidget {
  const _StopCard({
    required this.stop,
    required this.selected,
    required this.onTap,
  });

  final CachedStop stop;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: PuntoSpacing.s12),
      child: PuntoCard(
        color: selected ? context.primaryContainer : context.surfaceBright,
        border:
            selected ? Border.all(color: context.primary, width: 1.5) : null,
        elevation: selected ? PuntoEffects.floating : PuntoEffects.soft,
        borderRadius: PuntoBorders.md,
        padding: EdgeInsets.zero,
        child: Semantics(
          label: 'Seleccionar parada ${stop.name}',
          button: true,
          selected: selected,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(PuntoBorders.md),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: PuntoSpacing.md,
                vertical: PuntoSpacing.s12,
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected
                          ? context.surfaceBright
                          : context.primaryContainer,
                    ),
                    child: Icon(
                      stop.mode == TransportMode.metro
                          ? Icons.train_rounded
                          : Icons.directions_bus_rounded,
                      size: 20,
                      color: context.primary,
                    ),
                  ),
                  const SizedBox(width: PuntoSpacing.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stop.name,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: PuntoSpacing.xs),
                        Text(
                          '${stop.mode.name.toUpperCase()}'
                          '${stop.routeId != null ? ' · Ruta ${stop.routeId}' : ''}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: context.onSurfaceLow,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.chevron_right_rounded,
                    size: 20,
                    color: selected ? context.primary : context.onSurfaceLow,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Estado vacío ilustrado: ícono grande tintado + texto corto.
class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: PuntoSpacing.lg),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.primaryContainer,
              ),
              child: Icon(
                icon,
                size: 32,
                color: context.primary,
              ),
            ),
            const SizedBox(height: PuntoSpacing.md),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: PuntoSpacing.xs),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 260),
              child: Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.onSurfaceLow,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Estado de carga: esqueletos de tarjetas mientras se buscan paradas.
class _SkeletonList extends StatelessWidget {
  const _SkeletonList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (_) => Padding(
          padding: const EdgeInsets.only(bottom: PuntoSpacing.s12),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: context.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(PuntoBorders.md),
            ),
          ),
        ),
      ),
    );
  }
}

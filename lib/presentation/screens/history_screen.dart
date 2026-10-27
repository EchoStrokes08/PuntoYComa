import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../data/persistence/trip_history_repository.dart';
import '../../domain/entities/trip.dart';
import '../../design/design.dart';
import '../view_models/view_models.dart';

/// Pantalla de historial: recientes, favoritos y mapa de vista previa.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late HistoryViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = HistoryViewModel(
      historyRepository: TripHistoryRepositoryImpl(),
    );
    _viewModel.load();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PuntoScaffold(
      header: const PuntoScreenHeader(title: 'Tu historial'),
      child: SingleChildScrollView(
        child: AnimatedBuilder(
          animation: _viewModel,
          builder: (context, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: PuntoSpacing.sm),
              Text(
                'Tus viajes recientes y favoritos.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: PuntoSpacing.lg),

              if (_viewModel.isLoading && _viewModel.allTrips.isEmpty)
                const _SkeletonList()
              else if (_viewModel.allTrips.isEmpty)
                const _EmptyHistory()
              else ...[
                // ── Mapa de vista previa ─────────────────────────────
                _HistoryMapPreview(trips: _viewModel.allTrips),
                const SizedBox(height: PuntoSpacing.lg),

                // ── Favoritos ────────────────────────────────────────
                if (_viewModel.favorites.isNotEmpty) ...[
                  const _SectionTitle('Favoritos'),
                  ..._viewModel.favorites.map(
                    (trip) => _TripCard(
                      trip: trip,
                      isFavorite: true,
                      onTap: () => context.push('/preparacion', extra: trip),
                      onToggleFavorite: () =>
                          _viewModel.toggleFavorite(trip.id),
                    ),
                  ),
                  const SizedBox(height: PuntoSpacing.lg),
                ],

                // ── Recientes ────────────────────────────────────────
                const _SectionTitle('Recientes'),
                if (_viewModel.recents.isEmpty)
                  const Text('No hay viajes recientes.')
                else
                  ..._viewModel.recents.map(
                    (trip) => _TripCard(
                      trip: trip,
                      isFavorite: false,
                      onTap: () => context.push('/preparacion', extra: trip),
                      onToggleFavorite: () =>
                          _viewModel.toggleFavorite(trip.id),
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

/// Título de sección (titleSmall, tinta secundaria).
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: PuntoSpacing.s12),
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

/// Tarjeta de viaje: transporte, coordenadas, favorito y navegación.
class _TripCard extends StatelessWidget {
  const _TripCard({
    required this.trip,
    required this.isFavorite,
    required this.onTap,
    required this.onToggleFavorite,
  });

  final Trip trip;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: PuntoSpacing.s12),
      child: PuntoCard(
        color: context.surfaceBright,
        borderRadius: PuntoBorders.md,
        elevation: PuntoEffects.soft,
        padding: EdgeInsets.zero,
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
                    color: context.primaryContainer,
                  ),
                  child: Icon(
                    trip.mode == TransportMode.metro
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
                        '${trip.destination.latitude.toStringAsFixed(4)}, '
                        '${trip.destination.longitude.toStringAsFixed(4)}',
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: PuntoSpacing.xs),
                      Text(
                        '${trip.mode.name.toUpperCase()} · '
                        '${trip.alertLeadTime.inMinutes} min',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: context.onSurfaceLow,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Semantics(
                  label: isFavorite
                      ? 'Quitar de favoritos'
                      : 'Añadir a favoritos',
                  button: true,
                  child: IconButton(
                    icon: Icon(
                      isFavorite
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: isFavorite
                          ? context.warning
                          : context.onSurfaceLow,
                    ),
                    onPressed: onToggleFavorite,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Estado vacío ilustrado del historial.
class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: PuntoSpacing.xxl),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.primaryContainer,
              ),
              child: Icon(
                Icons.history_rounded,
                size: 36,
                color: context.primary,
              ),
            ),
            const SizedBox(height: PuntoSpacing.md),
            Text(
              'Aún no hay viajes',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: PuntoSpacing.xs),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 260),
              child: Text(
                'Cuando armes una alarma, tu historial aparecerá aquí.',
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

/// Estado de carga: esqueletos de tarjetas.
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

/// Mapa de vista previa que muestra los destinos del historial.
class _HistoryMapPreview extends StatelessWidget {
  const _HistoryMapPreview({required this.trips});

  final List<Trip> trips;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(PuntoBorders.md),
          child: SizedBox(
            height: 200,
            width: double.infinity,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  trips.first.destination.latitude,
                  trips.first.destination.longitude,
                ),
                zoom: 12,
              ),
              markers: {
                for (final trip in trips.take(6))
                  Marker(
                    markerId: MarkerId(trip.id),
                    position: LatLng(
                      trip.destination.latitude,
                      trip.destination.longitude,
                    ),
                    infoWindow: InfoWindow(
                      title:
                          '${trip.mode.name.toUpperCase()} · ${trip.alertLeadTime.inMinutes} min',
                    ),
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueRose,
                    ),
                  ),
              },
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: false,
              onMapCreated: (_) {},
            ),
          ),
        ),
      ],
    );
  }
}

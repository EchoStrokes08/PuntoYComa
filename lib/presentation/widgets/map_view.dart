import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../data/routing/local_stop_cache.dart';

import '../../design/design.dart';

/// Mapa interactivo con marcadores de paradas y posición del usuario.
///
/// [stops] son las paradas a mostrar como marcadores.
/// [selectedStop] es la parada actualmente seleccionada (se resalta).
/// [onStopTapped] se invoca cuando el usuario selecciona una parada del mapa.
/// [initialPosition] define el centro inicial del mapa.
class PuntoMapView extends StatefulWidget {
  const PuntoMapView({
    super.key,
    required this.stops,
    this.selectedStop,
    this.onStopTapped,
    this.initialPosition,
    this.height = 260,
  });

  final List<CachedStop> stops;
  final CachedStop? selectedStop;
  final ValueSetter<CachedStop>? onStopTapped;
  final LatLng? initialPosition;
  final double height;

  @override
  State<PuntoMapView> createState() => _PuntoMapViewState();
}

class _PuntoMapViewState extends State<PuntoMapView> {
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _buildMarkers();
  }

  void _buildMarkers() {
    _markers.clear();
    for (final stop in widget.stops) {
      final isSelected = widget.selectedStop?.id == stop.id;
      _markers.add(
        Marker(
          markerId: MarkerId(stop.id),
          position: LatLng(stop.latitude, stop.longitude),
          infoWindow: InfoWindow(
            title: stop.name,
            snippet: stop.routeId != null ? 'Ruta ${stop.routeId}' : null,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            isSelected
                ? BitmapDescriptor.hueAzure
                : BitmapDescriptor.hueGreen,
          ),
        ),
      );
    }
  }

  @override
  void didUpdateWidget(PuntoMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.stops != oldWidget.stops ||
        widget.selectedStop != oldWidget.selectedStop) {
      _buildMarkers();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.stops.isEmpty) {
      return _EmptyMap(context);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(PuntoBorders.md),
      child: Stack(
        children: [
          SizedBox(
            height: widget.height,
            width: double.infinity,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: widget.initialPosition ??
                    LatLng(
                      widget.stops.first.latitude,
                      widget.stops.first.longitude,
                    ),
                zoom: 14,
              ),
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: false,
              compassEnabled: true,
              onMapCreated: (_) {},
              onTap: (LatLng position) {
                // Encontrar la parada más cercana al toque
                CachedStop? nearest;
                double minDistance = double.infinity;
                for (final stop in widget.stops) {
                  final d = _distanceMeters(
                    position.latitude,
                    position.longitude,
                    stop.latitude,
                    stop.longitude,
                  );
                  if (d < minDistance && d < 100) {
                    minDistance = d;
                    nearest = stop;
                  }
                }
                if (nearest != null && widget.onStopTapped != null) {
                  widget.onStopTapped!(nearest);
                }
              },
            ),
          ),
          // Badge de "Tu ubicación"
          Positioned(
            top: 12,
            right: 12,
            child: _LocationBadge(),
          ),
        ],
      ),
    );
  }

  double _distanceMeters(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusKm = 6371.0;
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c * 1000;
  }

  double _degreesToRadians(double deg) => deg * (pi / 180);
}

class _EmptyMap extends StatelessWidget {
  const _EmptyMap(BuildContext context);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.surfaceContainer,
        borderRadius: BorderRadius.circular(PuntoBorders.md),
        border: Border.all(color: context.outline),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.map_outlined,
              size: 48,
              color: context.onSurfaceLow,
            ),
            const SizedBox(height: PuntoSpacing.sm),
            Text(
              'Sin paradas en el mapa',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: context.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: PuntoSpacing.xs),
            Text(
              'Agrega paradas recientes o busca cercanas para verlas aquí.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.onSurfaceLow,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(PuntoBorders.circle),
        boxShadow: [
          BoxShadow(
            color: PuntoColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.my_location_rounded,
            size: 16,
            color: PuntoColors.primary,
          ),
          const SizedBox(width: PuntoSpacing.xs),
          Text(
            'Tu ubicación',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: PuntoColors.primary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
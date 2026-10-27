import 'package:flutter/material.dart';

import '../../../domain/entities/trip.dart';

/// Tarjeta que muestra el destino del viaje armado.
///
/// Si se reconoce una parada conocida, muestra su nombre y detalle; si no,
/// muestra las coordenadas personalizadas.
class StopCard extends StatelessWidget {
  const StopCard({
    super.key,
    required this.trip,
    this.knownName,
    this.knownDetail,
    this.icon = Icons.place_rounded,
  });

  final Trip trip;
  final String? knownName;
  final String? knownDetail;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final title = knownName ?? 'Destino';
    final subtitle = knownDetail ??
        'lat ${trip.destination.latitude.toStringAsFixed(4)}, '
        'lng ${trip.destination.longitude.toStringAsFixed(4)}';

    return Semantics(
      label: 'Destino: $title. $subtitle.',
      child: Card(
        elevation: 0,
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
            child: Icon(icon, color: Theme.of(context).colorScheme.onSecondaryContainer),
          ),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right_rounded),
        ),
      ),
    );
  }
}

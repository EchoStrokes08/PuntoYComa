import '../entities/trip.dart';

/// Construye un resumen de historial listo para compartir sin exponer
/// coordenadas precisas.
///
/// La privacidad es un requisito del producto: el resumen redondea cada
/// destino a una celda de ~1 km (dos decimales) y lo declara explícitamente
/// en el texto exportado.
class HistoryExporter {
  const HistoryExporter._();

  static const _modeLabels = <TransportMode, String>{
    TransportMode.bus: 'Bus',
    TransportMode.train: 'Tren',
    TransportMode.metro: 'Metro',
  };

  static String buildSummary(List<Trip> trips, {DateTime? generatedAt}) {
    final now = generatedAt ?? DateTime.now();
    final unique = <String, Trip>{};
    for (final trip in trips) {
      unique.putIfAbsent(trip.id, () => trip);
    }
    final list = unique.values.toList();

    final buffer = StringBuffer()
      ..writeln('PuntoYcoma — resumen de viajes')
      ..writeln('Generado: ${_date(now)}')
      ..writeln('Total: ${list.length} ${list.length == 1 ? 'viaje' : 'viajes'}')
      ..writeln();

    if (list.isEmpty) {
      buffer.writeln('Todavía no hay viajes guardados.');
    } else {
      for (var i = 0; i < list.length; i++) {
        final trip = list[i];
        final mode = _modeLabels[trip.mode] ?? 'Transporte';
        final minutes = trip.alertLeadTime.inMinutes;
        final zone = _coarseZone(trip.destination);
        buffer.writeln(
          '${i + 1}. $mode · $minutes min de anticipación · zona $zone',
        );
      }
    }

    buffer
      ..writeln()
      ..writeln(
        'Las coordenadas se redondean a ~1 km para proteger tu privacidad.',
      );
    return buffer.toString();
  }

  /// Celda de ~1 km: el mismo criterio que usa el radar comunitario.
  static String _coarseZone(GeoPoint point) =>
      '${point.latitude.toStringAsFixed(2)}, '
      '${point.longitude.toStringAsFixed(2)}';

  static String _date(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month/${value.year} $hour:$minute';
  }
}

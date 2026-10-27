enum TransportMode { bus, train, metro }

enum TripStatus { draft, armed, approaching, alarmed, completed, cancelled }

class GeoPoint {
  const GeoPoint(this.latitude, this.longitude, {this.accuracyMeters = 0});
  final double latitude;
  final double longitude;
  final double accuracyMeters;
}

class Trip {
  const Trip({
    required this.id,
    required this.destination,
    required this.mode,
    required this.status,
    required this.alertLeadTime,
  });

  final String id;
  final GeoPoint destination;
  final TransportMode mode;
  final TripStatus status;
  final Duration alertLeadTime;

  /// Copia inmutable del viaje. Se usa para editar la alarma armada sin
  /// perder la identidad del viaje ni reiniciar la vigilancia.
  Trip copyWith({
    String? id,
    GeoPoint? destination,
    TransportMode? mode,
    TripStatus? status,
    Duration? alertLeadTime,
  }) {
    return Trip(
      id: id ?? this.id,
      destination: destination ?? this.destination,
      mode: mode ?? this.mode,
      status: status ?? this.status,
      alertLeadTime: alertLeadTime ?? this.alertLeadTime,
    );
  }
}

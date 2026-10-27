import '../entities/trip.dart';

/// Contrato para el historial local de viajes: recientes y favoritos.
///
/// Las operaciones son puras y síncronas en su firma (Future) pero no dependen
/// de la red ni de la lógica de alarma. El dominio nunca conoce la implementación
/// de almacenamiento.
abstract class TripHistoryRepository {
  /// Guarda un viaje en la lista de recientes.
  Future<void> saveRecent(Trip trip);

  /// Devuelve los viajes recientes, los más recientes primero.
  Future<List<Trip>> getRecents({int limit = 10});

  /// Alterna el estado de favorito de un viaje identificado por [tripId].
  Future<void> toggleFavorite(String tripId);

  /// Devuelve todos los viajes marcados como favoritos.
  Future<List<Trip>> getFavorites();

  /// Indica si un viaje está marcado como favorito.
  Future<bool> isFavorite(String tripId);

  /// Limpia la lista de recientes.
  Future<void> clearRecents();
}

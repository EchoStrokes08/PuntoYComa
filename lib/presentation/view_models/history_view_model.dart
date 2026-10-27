import 'package:flutter/foundation.dart';

import '../../domain/entities/trip.dart';
import '../../domain/services/history_export.dart';
import '../../domain/services/trip_history_contracts.dart';

/// ViewModel de la pantalla de historial (recientes y favoritos).
///
/// Gestiona la lista de viajes recientes y favoritos, permitiendo repetir
/// alarmas con un toque.
class HistoryViewModel extends ChangeNotifier {
  HistoryViewModel({required this.historyRepository});

  final TripHistoryRepository historyRepository;

  List<Trip> _recents = [];
  List<Trip> _favorites = [];
  bool _isLoading = false;
  String? _error;

  List<Trip> get recents => _recents;
  List<Trip> get favorites => _favorites;
  List<Trip> get allTrips {
    final ids = <String>{};
    final all = <Trip>[];
    for (final t in [..._recents, ..._favorites]) {
      if (ids.add(t.id)) all.add(t);
    }
    return all;
  }
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Carga recientes y favoritos del almacenamiento local.
  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final recentsFuture = historyRepository.getRecents(limit: 10);
      final favoritesFuture = historyRepository.getFavorites();

      _recents = await recentsFuture;
      _favorites = await favoritesFuture;
      notifyListeners();
    } catch (e) {
      _error = 'No se pudo cargar el historial';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Alterna el estado de favorito de un viaje.
  Future<void> toggleFavorite(String tripId) async {
    await historyRepository.toggleFavorite(tripId);
    await load();
  }

  /// Verifica si un viaje es favorito.
  Future<bool> isFavorite(String tripId) async =>
      historyRepository.isFavorite(tripId);

  /// Limpia la lista de recientes.
  Future<void> clearRecents() async {
    await historyRepository.clearRecents();
    await load();
  }

  /// Guarda un viaje completado en recientes.
  Future<void> saveCompleted(Trip trip) async {
    await historyRepository.saveRecent(trip);
    await load();
  }

  /// Resumen exportable: sin coordenadas precisas (celda de ~1 km).
  String buildExportSummary() => HistoryExporter.buildSummary(allTrips);
}

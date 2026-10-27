import 'package:flutter/foundation.dart';

import '../../data/routing/local_stop_cache.dart';
import '../../domain/entities/trip.dart';

/// ViewModel de la pantalla de destino.
///
/// Gestiona la selección de parada, el caché de paradas recientes y la
/// búsqueda de paradas cercanas sin depender de red.
class DestinationViewModel extends ChangeNotifier {
  DestinationViewModel({required this.stopCache});

  final LocalStopCache stopCache;

  List<CachedStop> _recentStops = [];
  List<CachedStop> _nearbyStops = [];
  List<CachedStop> _searchResults = [];
  CachedStop? _selectedStop;
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  List<CachedStop> get recentStops => _recentStops;
  List<CachedStop> get nearbyStops => _nearbyStops;
  List<CachedStop> get searchResults => _searchResults;
  CachedStop? get selectedStop => _selectedStop;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;

  /// Carga las paradas recientes del caché local.
  Future<void> loadRecents() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _recentStops = await stopCache.getStopsForRoute('recientes');
      notifyListeners();
    } catch (e) {
      _error = 'No se pudieron cargar las paradas recientes';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Selecciona una parada como destino.
  void selectStop(CachedStop stop) {
    _selectedStop = stop;
    notifyListeners();
  }

  /// Limpia la selección actual.
  void clearSelection() {
    _selectedStop = null;
    notifyListeners();
  }

  /// Guarda una parada en el caché de recientes.
  Future<void> saveRecent(CachedStop stop) async {
    await stopCache.saveStopsForRoute('recientes', [..._recentStops, stop]);
    await loadRecents();
  }

  /// Busca paradas cercanas a una coordenada (funciona sin internet).
  Future<void> loadNearby(double latitude, double longitude,
      {double radiusMeters = 5000}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _nearbyStops = await stopCache.nearbyStops(
        GeoPoint(latitude, longitude),
        radiusMeters: radiusMeters,
      );
      notifyListeners();
    } catch (e) {
      _error = 'No se pudieron cargar paradas cercanas';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Busca paradas por nombre en el caché local (filtro sin red).
  ///
  /// Devuelve paradas recientes y cercanas que coincidan con [query].
  void searchStops(String query) {
    _searchQuery = query.trim();
    notifyListeners();

    if (_searchQuery.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    final all = <CachedStop>{};
    all.addAll(_recentStops);
    all.addAll(_nearbyStops);

    _searchResults = all
        .where((stop) =>
            stop.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (stop.routeId != null &&
                stop.routeId!.toLowerCase().contains(_searchQuery.toLowerCase())))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    notifyListeners();
  }

  /// Limpia los resultados de búsqueda.
  void clearSearch() {
    _searchQuery = '';
    _searchResults = [];
    notifyListeners();
  }
}
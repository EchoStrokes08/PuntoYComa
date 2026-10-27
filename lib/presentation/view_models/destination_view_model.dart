import 'package:flutter/foundation.dart';

import '../../data/routing/local_stop_cache.dart';
import '../../data/routing/osm_stop_repository.dart';
import '../../domain/entities/trip.dart';

/// ViewModel de la pantalla de destino.
///
/// Gestiona la selección de parada, el caché de paradas recientes y la
/// búsqueda de paradas cercanas sin depender de red.
class DestinationViewModel extends ChangeNotifier {
  DestinationViewModel({
    required this.stopCache,
    this.remoteStops,
    this.resolveOrigin,
  });

  final LocalStopCache stopCache;

  /// Fuente remota opcional de paradas reales (OpenStreetMap).
  final OsmStopRepository? remoteStops;

  /// Resuelve el punto de búsqueda (ubicación del usuario o un centro por
  /// defecto). Si devuelve null no se buscan paradas cercanas.
  final Future<GeoPoint?> Function()? resolveOrigin;

  List<CachedStop> _recentStops = [];
  List<CachedStop> _nearbyStops = [];
  List<CachedStop> _searchResults = [];
  CachedStop? _selectedStop;
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  GeoPoint? _origin;
  bool _disposed = false;

  /// Punto desde el que se buscaron las paradas cercanas (null si aún no se
  /// resolvió).
  GeoPoint? get origin => _origin;

  /// Paradas a dibujar en el mapa: recientes + cercanas, sin duplicados.
  List<CachedStop> get mapStops {
    final byId = <String, CachedStop>{};
    for (final stop in [..._recentStops, ..._nearbyStops]) {
      byId.putIfAbsent(stop.id, () => stop);
    }
    return byId.values.toList();
  }

  @override
  void notifyListeners() {
    // Las cargas son asíncronas: evita notificar si la pantalla ya se cerró.
    if (_disposed) return;
    super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

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

  /// Carga las paradas cercanas al usuario: primero lo que haya en caché
  /// (funciona sin internet) y luego intenta traer paradas reales de la red
  /// para la zona, guardándolas en caché para la próxima vez.
  Future<void> loadNearbyFromOrigin() async {
    final origin = await resolveOrigin?.call();
    if (origin == null || _disposed) return;
    _origin = origin;
    notifyListeners();

    await loadNearby(origin.latitude, origin.longitude);

    final remote = remoteStops;
    if (remote == null || _disposed) return;
    try {
      final fetched = await remote.fetchNearby(origin);
      if (fetched.isEmpty || _disposed) return;
      await stopCache.saveStopsForRoute(
        OsmStopRepository.cacheKey(origin),
        fetched,
      );
      await loadNearby(origin.latitude, origin.longitude);
    } catch (_) {
      // Sin red o servidor caído: se queda con lo que ya hay en caché.
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
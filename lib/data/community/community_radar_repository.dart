import '../../domain/services/community_radar_contracts.dart';
import 'community_api.dart';

/// Implementación de [CommunityRadar] sobre la API REST del servidor
/// comunitario.
///
/// Todas las operaciones son opcionales: si el servidor no responde, se
/// lanza una excepción que los llamadores deben manejar sin afectar la
/// alarma local.
class CommunityRadarRepository implements CommunityRadar {
  CommunityRadarRepository({required CommunityApiClient api})
      : _api = api;

  final CommunityApiClient _api;

  @override
  Future<void> report({
    required String routeId,
    required double latitude,
    required double longitude,
    required String category,
    required String installationId,
  }) async {
    await _api.postReport(
      routeId: routeId,
      latitude: latitude,
      longitude: longitude,
      category: category,
      installationId: installationId,
    );
  }

  @override
  Future<Map<String, int>> feed({
    required String routeId,
    required double latitude,
    required double longitude,
  }) async {
    return _api.getFeed(
      routeId: routeId,
      latitude: latitude,
      longitude: longitude,
    );
  }

  @override
  Future<bool> healthCheck() async => _api.healthCheck();
}

/// Implementación de [CommunityRadar] para tests y entornos sin red.
/// Todas las operaciones son no-operativas y devuelven valores por defecto.
class CommunityRadarStub implements CommunityRadar {
  final Map<String, int> _feed = <String, int>{};
  final List<Map<String, dynamic>> _reports = <Map<String, dynamic>>[];

  @override
  Future<void> report({
    required String routeId,
    required double latitude,
    required double longitude,
    required String category,
    required String installationId,
  }) async {
    _reports.add(<String, dynamic>{
      'routeId': routeId,
      'latitude': latitude,
      'longitude': longitude,
      'category': category,
      'installationId': installationId,
    });
  }

  @override
  Future<Map<String, int>> feed({
    required String routeId,
    required double latitude,
    required double longitude,
  }) async {
    return Map<String, int>.unmodifiable(_feed);
  }

  @override
  Future<bool> healthCheck() async => true;

  /// Para tests: establecer conteos de feed devueltos.
  void setFeed(Map<String, int> counts) {
    _feed.clear();
    _feed.addAll(counts);
  }

  /// Para tests: obtener todos los reportes enviados.
  List<Map<String, dynamic>> get sentReports => List.unmodifiable(_reports);
}

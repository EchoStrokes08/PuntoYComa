import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/entities/trip.dart';
import 'local_stop_cache.dart';

/// Obtiene paradas reales de transporte público desde OpenStreetMap
/// (API Overpass, gratuita y sin clave).
///
/// Privacidad: la app promete que la posición exacta no sale del
/// dispositivo. Por eso nunca se envía la ubicación del usuario tal cual:
/// se redondea a una celda de 0.01° (~1.1 km) y se consulta alrededor del
/// centro de esa celda. El servidor solo aprende en qué barrio estás.
///
/// Es opcional: si no hay red o el servidor falla, quien llama sigue con lo
/// que ya haya en [LocalStopCache].
class OsmStopRepository {
  OsmStopRepository({
    http.Client? client,
    this.endpoint = 'https://overpass-api.de/api/interpreter',
    this.radiusMeters = 1500,
    this.timeout = const Duration(seconds: 20),
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final String endpoint;
  final double radiusMeters;
  final Duration timeout;

  /// Tamaño de celda en grados (~1.1 km) usado para anonimizar la consulta.
  static const double cellSizeDegrees = 0.01;

  /// Centro de la celda de [point]: lo único que se envía al servidor.
  static GeoPoint cellCenter(GeoPoint point) {
    double snap(double v) =>
        ((v / cellSizeDegrees).floor() + 0.5) * cellSizeDegrees;
    return GeoPoint(snap(point.latitude), snap(point.longitude));
  }

  /// Clave de caché estable para la celda de [point].
  static String cacheKey(GeoPoint point) {
    final c = cellCenter(point);
    return 'cercanas.${c.latitude.toStringAsFixed(3)}'
        '.${c.longitude.toStringAsFixed(3)}';
  }

  /// Paradas con nombre alrededor de la celda de [origin].
  ///
  /// Lanza si la red falla o el servidor responde con error.
  Future<List<CachedStop>> fetchNearby(GeoPoint origin) async {
    final center = cellCenter(origin);
    final response = await _client
        .post(
          Uri.parse(endpoint),
          headers: const {
            'User-Agent': 'PuntoYComa/0.1 (app de alarma de transporte)',
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: {'data': buildQuery(center, radiusMeters)},
        )
        .timeout(timeout);

    if (response.statusCode != 200) {
      throw http.ClientException(
        'Overpass respondió ${response.statusCode}',
        Uri.parse(endpoint),
      );
    }
    return parseResponse(utf8.decode(response.bodyBytes));
  }

  /// Consulta Overpass QL para buses, estaciones de bus y tren/metro/tranvía.
  static String buildQuery(GeoPoint center, double radius) {
    final around = 'around:${radius.round()},'
        '${center.latitude.toStringAsFixed(5)},'
        '${center.longitude.toStringAsFixed(5)}';
    return '[out:json][timeout:15];'
        '('
        'node["highway"="bus_stop"]["name"]($around);'
        'node["amenity"="bus_station"]["name"]($around);'
        'node["railway"~"^(station|halt|tram_stop)\$"]["name"]($around);'
        ');'
        'out body 80;';
  }

  /// Convierte la respuesta JSON de Overpass en [CachedStop]s.
  /// Ignora elementos sin coordenadas o sin nombre; sin duplicados por id.
  static List<CachedStop> parseResponse(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) return const [];
    final elements = decoded['elements'];
    if (elements is! List) return const [];

    final seen = <String>{};
    final stops = <CachedStop>[];
    for (final element in elements) {
      if (element is! Map<String, dynamic>) continue;
      final lat = element['lat'];
      final lon = element['lon'];
      final tags = element['tags'];
      if (lat is! num || lon is! num || tags is! Map) continue;
      final name = (tags['name'] as String?)?.trim();
      if (name == null || name.isEmpty) continue;

      final id = 'osm:${element['id']}';
      if (!seen.add(id)) continue;

      stops.add(
        CachedStop(
          id: id,
          name: name,
          latitude: lat.toDouble(),
          longitude: lon.toDouble(),
          mode: _modeFor(tags),
        ),
      );
    }
    return stops;
  }

  static TransportMode _modeFor(Map tags) {
    final railway = tags['railway'];
    if (railway == 'station' || railway == 'halt' || railway == 'tram_stop') {
      final isSubway = tags['station'] == 'subway' || tags['subway'] == 'yes';
      return isSubway ? TransportMode.metro : TransportMode.train;
    }
    return TransportMode.bus;
  }
}

import 'dart:convert';

import 'package:http/http.dart' as http;

/// Cliente HTTP para la API comunitaria de PuntoYcoma.
///
/// Toda la comunicación es opcional: si el servidor no está disponible, la
/// alarma local sigue funcionando normalmente. Este cliente nunca envía
/// coordenadas precisas ni el viaje activo del usuario.
class CommunityApiClient {
  CommunityApiClient({
    required this.baseUrl,
    http.Client? client,
    this.timeoutSeconds = 10,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;
  final int timeoutSeconds;

  /// Envía un reporte anónimo al servidor.
  ///
  /// Lanza [http.ClientException] si la red falla o el servidor responde
  /// con un error. Los llamadores deben manejar la excepción y no bloquear
  /// la alarma local.
  Future<void> postReport({
    required String routeId,
    required double latitude,
    required double longitude,
    required String category,
    required String installationId,
  }) async {
    final uri = Uri.parse('$baseUrl/v1/community/reports');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(<String, dynamic>{
        'routeId': routeId,
        'category': category,
        'latitude': latitude,
        'longitude': longitude,
        'installationId': installationId,
      }),
    ).timeout(Duration(seconds: timeoutSeconds));

    if (response.statusCode == 429) {
      throw const RateLimitedException();
    }
    if (response.statusCode >= 400) {
      throw HttpException(response.statusCode, response.body);
    }
  }

  /// Obtiene conteos agregados de reportes para una ruta y celda.
  ///
  /// Devuelve un mapa de categoría → cantidad. Nunca devuelve posiciones
  /// individuales.
  Future<Map<String, int>> getFeed({
    required String routeId,
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse('$baseUrl/v1/community/feed').replace(
      queryParameters: <String, String>{
        'routeId': routeId,
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
      },
    );
    final response = await _client.get(uri).timeout(
      Duration(seconds: timeoutSeconds),
    );
    if (response.statusCode >= 400) {
      throw HttpException(response.statusCode, response.body);
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final reports = data['reports'] as List<dynamic>;
    return <String, int>{
      for (final entry in reports) entry['category'] as String: entry['count'] as int,
    };
  }

  /// Verifica que el servidor esté disponible.
  Future<bool> healthCheck() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/health'),
      ).timeout(Duration(seconds: timeoutSeconds));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    _client.close();
  }
}

/// Excepción lanzada cuando el servidor rate-limita al reporter.
class RateLimitedException implements Exception {
  const RateLimitedException();
  @override
  String toString() => 'Reporter rate limited by community API';
}

/// Excepción lanzada por errores HTTP del servidor comunitario.
class HttpException implements Exception {
  final int statusCode;
  final String body;
  const HttpException(this.statusCode, this.body);
  @override
  String toString() => 'Community API error $statusCode: $body';
}

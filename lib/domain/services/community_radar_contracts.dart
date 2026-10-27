/// Contrato para el radar comunitario de reportes anónimos.
///
/// El radar comunitario es opcional y está completamente separado de la
/// lógica de alarma local. Las coordenadas se envían redondeadas a una celda
/// de ~1 km y el identificador de instalación rota diariamente, por lo que
/// nunca se pueden rastrear posiciones individuales.
abstract class CommunityRadar {
  /// Envía un reporte anónimo al servidor comunitario.
  ///
  /// [category] es uno de: crowded, delay, safety, accessibility.
  /// [installationId] es el UUID de la instalación (se rota diariamente en el backend).
  Future<void> report({
    required String routeId,
    required double latitude,
    required double longitude,
    required String category,
    required String installationId,
  });

  /// Obtiene conteos agregados de reportes para una ruta y celda.
  ///
  /// Devuelve un mapa de categoría → cantidad. Nunca devuelve posiciones
  /// individuales ni identificadores de instalación.
  Future<Map<String, int>> feed({
    required String routeId,
    required double latitude,
    required double longitude,
  });

  /// Indica si el servidor comunitario está disponible.
  Future<bool> healthCheck();
}

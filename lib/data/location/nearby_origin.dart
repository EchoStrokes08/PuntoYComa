import 'package:geolocator/geolocator.dart';

import '../../domain/entities/trip.dart';

/// Punto desde el que se buscan paradas cercanas en la pantalla de destino.
///
/// La app pide permiso de ubicación solo al armar una alarma, nunca antes;
/// por eso aquí jamás se solicita permiso:
/// - con permiso ya concedido, usa la última posición conocida o una lectura
///   rápida de baja precisión;
/// - sin permiso (o si la lectura falla), usa [fallbackCenter] para que el
///   mapa y las paradas sigan siendo útiles.
///
/// Devuelve null solo si la plataforma no responde en absoluto (por ejemplo
/// en pruebas, donde el plugin de ubicación no existe).
class NearbyOrigin {
  const NearbyOrigin({this.fallbackCenter = bogota});

  /// Centro de Bogotá, usado cuando no hay ubicación disponible.
  static const GeoPoint bogota = GeoPoint(4.7110, -74.0721);

  final GeoPoint fallbackCenter;

  Future<GeoPoint?> resolve() async {
    try {
      final permission = await Geolocator.checkPermission();
      final granted = permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
      if (!granted) return fallbackCenter;

      try {
        final position = await Geolocator.getLastKnownPosition() ??
            await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.low,
                timeLimit: Duration(seconds: 8),
              ),
            );
        return GeoPoint(position.latitude, position.longitude);
      } catch (_) {
        return fallbackCenter;
      }
    } catch (_) {
      return null;
    }
  }
}

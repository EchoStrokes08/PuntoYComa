import 'package:flutter/services.dart';

/// Abre la hoja de compartir del sistema con texto plano. En plataformas sin
/// canal nativo (web/escritorio/test) devuelve `false` y la UI cae al
/// portapapeles.
class ShareBridge {
  const ShareBridge();

  static const _channel = MethodChannel('punto_y_coma/share');

  Future<bool> shareText(String text) async {
    try {
      final result = await _channel.invokeMethod<bool>('shareText', {
        'text': text,
      });
      return result ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}

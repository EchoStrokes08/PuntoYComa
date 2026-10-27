/// Interfaz de almacenamiento clave-valor cifrado.
///
/// Permite probar repositorios sin depender de la implementación nativa
/// de `flutter_secure_storage` (que requiere un canal de plataforma).
abstract class SecureStorage {
  Future<void> write({required String key, required String value});
  Future<String?> read({required String key});
  Future<Map<String, String>> readAll();
  Future<void> delete({required String key});
}

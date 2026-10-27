import '../../domain/services/secure_storage_contracts.dart';

/// Implementación en memoria de [SecureStorage] para pruebas y entornos sin
/// plataforma nativa (web/desktop/test).
class InMemorySecureStorage implements SecureStorage {
  final Map<String, String> _data = {};

  @override
  Future<void> write({required String key, required String value}) async {
    _data[key] = value;
  }

  @override
  Future<String?> read({required String key}) async => _data[key];

  @override
  Future<Map<String, String>> readAll() async =>
      Map<String, String>.unmodifiable(_data);

  @override
  Future<void> delete({required String key}) async {
    _data.remove(key);
  }
}

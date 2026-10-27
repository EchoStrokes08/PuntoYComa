import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/services/secure_storage_contracts.dart';

/// Adaptador de [SecureStorage] sobre `flutter_secure_storage` para producción.
class FlutterSecureStorageAdapter implements SecureStorage {
  FlutterSecureStorageAdapter([this._storage = const FlutterSecureStorage()]);
  final FlutterSecureStorage _storage;

  @override
  Future<void> write({required String key, required String value}) =>
      _storage.write(key: key, value: value);

  @override
  Future<String?> read({required String key}) => _storage.read(key: key);

  @override
  Future<Map<String, String>> readAll() => _storage.readAll();

  @override
  Future<void> delete({required String key}) => _storage.delete(key: key);
}

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Guarda el JWT de CEOSMOS.
abstract interface class TokenStore {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> clear();
}

/// Almacenamiento seguro del sistema (Android Keystore / iOS Keychain).
///
/// Usa un archivo y un prefijo propios de CEOSMOS: la práctica MediConnect
/// usa el almacén por defecto y llama a `deleteAll()` al cerrar su sesión;
/// con este nombre separado nunca borra ni lee el token de CEOSMOS.
class SecureTokenStore implements TokenStore {
  static const _key = 'jwt';
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      // Aísla archivo, prefijo y alias del KeyStore respecto de otros usos.
      storageNamespace: 'ceosmos_secure_storage',
    ),
    iOptions: IOSOptions(
      accountName: 'ceosmos',
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  @override
  Future<String?> read() => _storage.read(key: _key);
  @override
  Future<void> write(String token) => _storage.write(key: _key, value: token);
  @override
  Future<void> clear() => _storage.delete(key: _key);
}

/// Almacén en memoria para pruebas automatizadas.
class MemoryTokenStore implements TokenStore {
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String token) async => value = token;
  @override
  Future<void> clear() async => value = null;
}

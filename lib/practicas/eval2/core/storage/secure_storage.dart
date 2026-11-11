import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Tokens guardados en el almacenamiento seguro del sistema
/// (Android Keystore / EncryptedSharedPreferences, iOS Keychain).
/// Nunca en SharedPreferences ni archivos comunes.
class SecureStorage {
  static const _storage = FlutterSecureStorage(
    // v10+: cifrado con llaves del Android Keystore activado por defecto.
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
  );
  static const _access = 'access_token';
  static const _refresh = 'refresh_token';

  Future<void> saveTokens(String access, String refresh) async {
    await _storage.write(key: _access, value: access);
    await _storage.write(key: _refresh, value: refresh);
  }

  Future<String?> get accessToken => _storage.read(key: _access);
  Future<String?> get refreshToken => _storage.read(key: _refresh);

  /// Se llama al cerrar sesion o si falla la renovacion del token.
  Future<void> clear() => _storage.deleteAll();
}

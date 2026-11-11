import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import '../domain/models.dart';

abstract interface class AuthRepository {
  Future<AuthSession> login(String email, String password);
  Future<AuthSession> register(String name, String email, String password);
  Future<AuthSession> enterDemo();
  Future<void> logout();
}

class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;
}

/// Educational, volatile accounts. Never used as a production auth mechanism.
/// Salted digests only live in RAM; no credentials or tokens go to disk.
class MemoryAuthRepository implements AuthRepository {
  MemoryAuthRepository({DateTime Function()? now}) : _now = now ?? DateTime.now;
  final DateTime Function() _now;
  final Map<String, ({AppUser user, String salt, String digest})> _accounts =
      {};
  static const demoUser = AppUser(
    id: 'demo',
    email: 'demo@ceosmos.local',
    username: 'Explorador',
  );
  AuthSession _session(AppUser user) =>
      AuthSession(user: user, expiresAt: _now().add(const Duration(hours: 2)));
  String _digest(String salt, String password) =>
      sha256.convert(utf8.encode('$salt:$password')).toString();

  @override
  Future<AuthSession> login(String email, String password) async {
    final account = _accounts[email.trim().toLowerCase()];
    if (account == null || account.digest != _digest(account.salt, password)) {
      throw const AuthFailure(
        'Correo o contraseña incorrectos. Crea una cuenta local o entra a la demo.',
      );
    }
    return _session(account.user);
  }

  @override
  Future<AuthSession> register(
    String name,
    String email,
    String password,
  ) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (name.trim().length < 2 ||
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(normalizedEmail) ||
        password.length < 8) {
      throw const AuthFailure(
        'Revisa tu nombre, correo y contraseña (mínimo 8 caracteres).',
      );
    }
    if (_accounts.containsKey(normalizedEmail)) {
      throw const AuthFailure(
        'Este correo ya tiene una cuenta local. Inicia sesión.',
      );
    }
    final random = Random.secure();
    final salt = List.generate(24, (_) => random.nextInt(256)).join('-');
    final user = AppUser(
      id: 'local-${_accounts.length + 1}',
      email: normalizedEmail,
      username: name.trim(),
    );
    _accounts[normalizedEmail] = (
      user: user,
      salt: salt,
      digest: _digest(salt, password),
    );
    return _session(user);
  }

  @override
  Future<AuthSession> enterDemo() async => _session(demoUser);
  @override
  Future<void> logout() async {}
}

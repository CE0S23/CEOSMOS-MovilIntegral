import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models.dart';

/// Copia local mínima para abrir CEOSMOS sin red (PWA instalada o teléfono sin datos):
///
/// * el **perfil público** del usuario (id, correo, nombre, rol, minutos preferidos),
///   nunca la contraseña ni el token: el JWT sigue en el almacenamiento seguro;
/// * las **sesiones de enfoque pendientes** (terminadas sin red), para que no se
///   pierdan si se cierra la app antes de que vuelva la conexión.
///
/// Se borra completa al cerrar sesión o cuando el servidor revoca el token.
abstract interface class CacheSinConexion {
  Future<AppUser?> leerPerfil();
  Future<void> guardarPerfil(AppUser usuario);
  Future<List<FocusSession>> leerPendientes(String userId);
  Future<void> guardarPendientes(String userId, List<FocusSession> pendientes);
  Future<void> borrar();
}

/// Serialización compartida por las implementaciones (formato de `GET /users/me`).
abstract final class FormatoSinConexion {
  static Map<String, Object?> perfil(AppUser u) => {
        'id': u.id,
        'email': u.email,
        'username': u.username,
        'role': u.isAdmin ? 'ADMIN' : 'USER',
        'emailVerified': u.emailVerified,
        'preferences': {'flowTimeDefault': u.preferredMinutes},
        'createdAt': u.createdAt?.toUtc().toIso8601String(),
      };

  static Map<String, Object?> pendiente(FocusSession s) => {...s.toJson(), 'id': s.id};

  /// Una sesión pendiente vuelve sin confirmar y conserva su `clientId` (idempotencia).
  static FocusSession leerPendiente(Map<String, dynamic> json) {
    final s = FocusSession.fromJson(json);
    return FocusSession(
      id: s.id,
      contentKey: s.contentKey,
      mode: s.mode,
      startedAt: s.startedAt,
      endedAt: s.endedAt,
      durationSeconds: s.durationSeconds,
      targetMinutes: s.targetMinutes,
      completed: s.completed,
      metadata: s.metadata,
      synced: false,
      clientId: s.clientId,
    );
  }
}

/// Implementación real: SharedPreferences (Android) o localStorage (PWA).
class CachePreferencias implements CacheSinConexion {
  static const _perfil = 'ceosmos.sin_conexion.perfil';
  static const _pendientes = 'ceosmos.sin_conexion.pendientes.';

  @override
  Future<AppUser?> leerPerfil() async {
    try {
      final texto = (await SharedPreferences.getInstance()).getString(_perfil);
      if (texto == null) return null;
      return AppUser.fromJson(jsonDecode(texto) as Map<String, dynamic>);
    } catch (_) {
      return null; // copia dañada o ilegible: se pide iniciar sesión con red
    }
  }

  @override
  Future<void> guardarPerfil(AppUser usuario) async =>
      (await SharedPreferences.getInstance()).setString(_perfil, jsonEncode(FormatoSinConexion.perfil(usuario)));

  @override
  Future<List<FocusSession>> leerPendientes(String userId) async {
    try {
      final texto = (await SharedPreferences.getInstance()).getString('$_pendientes$userId');
      if (texto == null) return [];
      return [
        for (final j in jsonDecode(texto) as List) FormatoSinConexion.leerPendiente((j as Map).cast<String, dynamic>()),
      ];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> guardarPendientes(String userId, List<FocusSession> pendientes) async {
    final prefs = await SharedPreferences.getInstance();
    if (pendientes.isEmpty) {
      await prefs.remove('$_pendientes$userId');
    } else {
      await prefs.setString('$_pendientes$userId', jsonEncode([for (final p in pendientes) FormatoSinConexion.pendiente(p)]));
    }
  }

  @override
  Future<void> borrar() async {
    final prefs = await SharedPreferences.getInstance();
    for (final k in prefs.getKeys().where((k) => k.startsWith('ceosmos.sin_conexion.')).toList()) {
      await prefs.remove(k);
    }
  }
}

/// Implementación en memoria (pruebas y valor por defecto). Guarda el mismo JSON que
/// la real para que las pruebas cubran la serialización.
class CacheEnMemoria implements CacheSinConexion {
  String? perfil;
  final pendientes = <String, String>{};

  @override
  Future<AppUser?> leerPerfil() async =>
      perfil == null ? null : AppUser.fromJson(jsonDecode(perfil!) as Map<String, dynamic>);

  @override
  Future<void> guardarPerfil(AppUser usuario) async => perfil = jsonEncode(FormatoSinConexion.perfil(usuario));

  @override
  Future<List<FocusSession>> leerPendientes(String userId) async {
    final texto = pendientes[userId];
    if (texto == null) return [];
    return [
      for (final j in jsonDecode(texto) as List) FormatoSinConexion.leerPendiente((j as Map).cast<String, dynamic>()),
    ];
  }

  @override
  Future<void> guardarPendientes(String userId, List<FocusSession> lista) async {
    if (lista.isEmpty) {
      pendientes.remove(userId);
    } else {
      pendientes[userId] = jsonEncode([for (final p in lista) FormatoSinConexion.pendiente(p)]);
    }
  }

  @override
  Future<void> borrar() async {
    perfil = null;
    pendientes.clear();
  }
}

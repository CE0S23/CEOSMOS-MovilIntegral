// Doble de prueba de la API de CEOSMOS (NestJS) para pruebas automatizadas.
// Reproduce el contrato HTTP que usa la app: auth, users, favorites,
// focus-sessions, devices y media, con datos separados por usuario.
import 'dart:convert';

import 'package:ceosmos_movil_integral/core/app_state.dart';
import 'package:ceosmos_movil_integral/core/ble/ecosistema_ble.dart';
import 'package:ceosmos_movil_integral/core/reintentos.dart';
import 'package:ceosmos_movil_integral/core/wearable.dart';
import 'package:ceosmos_movil_integral/data/api_client.dart';
import 'package:ceosmos_movil_integral/data/auth_repository.dart';
import 'package:ceosmos_movil_integral/data/cache_sin_conexion.dart';
import 'package:ceosmos_movil_integral/data/ceosmos_repository.dart';
import 'package:ceosmos_movil_integral/data/token_store.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class FakeUser {
  FakeUser(this.id, this.email, this.username, this.password, {this.role = 'USER', this.verified = true});
  final String id, email, password, role;
  String username;
  bool verified;
  int minutes = 25;
  final Set<String> favorites = {};
  final List<Map<String, dynamic>> sessions = [];
  final List<Map<String, dynamic>> devices = [];
  final List<Map<String, dynamic>> media = [];
}

class FakeCeosmosApi {
  final Map<String, FakeUser> users = {};
  final Map<String, String> tokens = {}; // token -> userId
  final List<String> calls = [];
  final Map<String, String> verificationCodes = {};
  int _seq = 0;

  /// Si es true todas las peticiones fallan como sin red.
  bool offline = false;

  /// Si es true, `POST /focus-sessions` responde 400 (rechazo definitivo, P12-D02).
  bool rechazarSesiones = false;

  FakeUser addUser(String email, String password, {String username = 'usuario', String role = 'USER', bool verified = true}) {
    final u = FakeUser('u${++_seq}', email, username, password, role: role, verified: verified);
    users[u.id] = u;
    return u;
  }

  void revokeAll() => tokens.clear();

  late final http.Client client = MockClient(_handle);

  http.Response _json(int status, Object? body) => http.Response(
    body == null ? '' : jsonEncode(body),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );

  http.Response _error(int status, String message) =>
      _json(status, {'statusCode': status, 'message': message, 'error': 'ERROR'});

  Map<String, dynamic> _me(FakeUser u) => {
    'id': u.id,
    'email': u.email,
    'username': u.username,
    'emailVerified': u.verified,
    'role': u.role,
    'createdAt': '2026-11-01T10:00:00.000Z',
    'preferences': {'flowTimeDefault': u.minutes, 'theme': 'dark'},
  };

  Future<http.Response> _handle(http.Request req) async {
    if (offline) throw http.ClientException('offline');
    final path = req.url.path.replaceFirst('/api', '');
    calls.add('${req.method} $path');
    final body = req.body.isEmpty ? <String, dynamic>{} : (jsonDecode(req.body) as Map).cast<String, dynamic>();

    // --- Rutas públicas ---
    if (req.method == 'POST' && path == '/auth/login') {
      final u = users.values.where((u) => u.email == body['email']).firstOrNull;
      if (u == null || u.password != body['password']) return _error(401, 'Invalid credentials');
      if (!u.verified) return _error(401, 'Email not verified');
      final token = 'tok-${++_seq}';
      tokens[token] = u.id;
      return _json(200, {'success': true, 'token': token});
    }
    if (req.method == 'POST' && path == '/auth/register') {
      if (users.values.any((u) => u.email == body['email'] || u.username == body['username'])) {
        return _error(400, 'Email or username already in use');
      }
      final u = addUser(body['email'] as String, body['password'] as String,
          username: body['username'] as String, verified: false);
      verificationCodes[u.email] = 'A1B2C3';
      return _json(201, {'message': 'User created. Check your email for the verification code.'});
    }
    if (req.method == 'POST' && path == '/auth/verify-email') {
      if (verificationCodes[body['email']] != body['code']) return _error(400, 'Invalid or expired code');
      users.values.firstWhere((u) => u.email == body['email']).verified = true;
      return _json(200, {'message': 'Email verified successfully'});
    }
    if (req.method == 'POST' && (path == '/auth/forgot-password' || path == '/auth/resend-verification')) {
      return _json(200, {'message': 'ok'});
    }

    // --- Rutas protegidas ---
    final auth = req.headers['Authorization'] ?? req.headers['authorization'] ?? '';
    final uid = tokens[auth.replaceFirst('Bearer ', '')];
    final u = uid == null ? null : users[uid];
    if (u == null) return _error(401, 'Unauthorized');

    switch ((req.method, path)) {
      case ('POST', '/auth/logout'):
        tokens.removeWhere((_, v) => v == u.id);
        return _json(200, {'success': true});
      case ('GET', '/users/me'):
        return _json(200, _me(u));
      case ('GET', '/users/me/sessions'):
        return _json(200, [
          {'id': 's1', 'createdAt': '2026-11-11T10:00:00.000Z', 'ipAddress': '10.0.2.16'},
        ]);
      case ('PATCH', '/users/preferences'):
        final m = body['flowTimeDefault'] as int;
        if (m < 5 || m > 180) return _error(400, 'flowTimeDefault must not be less than 5');
        u.minutes = m;
        return _json(200, _me(u));
      case ('PATCH', '/users/profile'):
        u.username = body['username'] as String;
        return _json(200, _me(u));
      case ('DELETE', '/users/me'):
        users.remove(u.id);
        return _json(200, {'message': 'deleted'});
      case ('GET', '/favorites'):
        return _json(200, [for (final f in u.favorites) {'contentKey': f}]);
      case ('GET', '/focus-sessions'):
        // Como la API (P12-O1): orden descendente, `limit` y `cursor` (id de la última).
        var ordenadas = [...u.sessions]..sort((a, b) => '${b['startedAt']}'.compareTo('${a['startedAt']}'));
        final cursor = req.url.queryParameters['cursor'];
        if (cursor != null) ordenadas = ordenadas.skipWhile((x) => x['id'] != cursor).skip(1).toList();
        final limite = int.tryParse(req.url.queryParameters['limit'] ?? '') ?? 50;
        return _json(200, ordenadas.take(limite).toList());
      case ('GET', '/focus-sessions/resumen'):
        return _json(200, {
          'sesiones': u.sessions.length,
          'segundos': u.sessions.fold<int>(0, (s, x) => s + (x['durationSeconds'] as num).toInt()),
        });
      case ('POST', '/focus-sessions') when rechazarSesiones:
        return _error(400, 'endedAt no puede estar en el futuro');
      case ('POST', '/focus-sessions'):
        // Igual que la API corregida (P11-D01): mismo clientId → misma sesión.
        final previa = u.sessions.where((x) => body['clientId'] != null && x['clientId'] == body['clientId']).firstOrNull;
        if (previa != null) return _json(201, previa);
        final s = {...body, 'id': 'fs-${++_seq}'};
        u.sessions.add(s);
        return _json(201, s);
      case ('GET', '/devices'):
        return _json(200, u.devices);
      case ('POST', '/devices'):
        // Igual que la API: único por (usuario, tipo, dirección).
        if (u.devices.any((d) => d['address'] == body['address'] && (d['type'] ?? 'WEARABLE') == (body['type'] ?? 'WEARABLE'))) {
          return _error(409, 'Ese dispositivo ya está vinculado.');
        }
        final d = {...body, 'id': '00000000-0000-4000-8000-${(++_seq).toString().padLeft(12, '0')}', 'lastSeenAt': null};
        u.devices.add(d);
        return _json(201, d);
      case ('GET', '/media'):
        return _json(200, u.media);
      case ('POST', '/media'):
        if (u.media.any((m) => (body['externalId'] != null && m['externalId'] == body['externalId']) ||
            (body['url'] != null && m['url'] == body['url']))) {
          return _error(409, 'This image URL is already saved');
        }
        final m = {...body, 'id': 'm-${++_seq}'};
        u.media.insert(0, m);
        return _json(201, m);
    }
    if (path.startsWith('/favorites/')) {
      final key = Uri.decodeComponent(path.substring('/favorites/'.length));
      if (req.method == 'PUT') u.favorites.add(key);
      if (req.method == 'DELETE') u.favorites.remove(key);
      return req.method == 'PUT' ? _json(200, {'contentKey': key}) : _json(204, null);
    }
    if (path.startsWith('/devices/')) {
      final id = path.substring('/devices/'.length);
      final d = u.devices.where((d) => d['id'] == id).firstOrNull;
      if (d == null) return _error(404, 'Dispositivo no encontrado');
      if (req.method == 'DELETE') {
        u.devices.remove(d);
        return _json(204, null);
      }
      if (body['seen'] == true) d['lastSeenAt'] = '2026-11-11T12:00:00.000Z';
      return _json(200, d);
    }
    if (path.startsWith('/media/') && req.method == 'DELETE') {
      u.media.removeWhere((m) => m['id'] == path.substring('/media/'.length));
      return _json(204, null);
    }
    return _error(404, 'Recurso no encontrado');
  }

  /// AppState conectado a este servidor falso.
  AppState appState({
    DateTime Function()? now,
    WearableClient? wearable,
    EcosistemaBle? ble,
    MemoryTokenStore? tokens,
    PoliticaReintento reintentos = const PoliticaReintento(),
    CacheSinConexion? cache,
  }) {
    final api = ApiClient(baseUrl: 'http://api.test/api', client: client);
    return AppState(
      auth: AuthRepository(api, tokens ?? MemoryTokenStore()),
      data: CeosmosRepository(api),
      wearable: wearable,
      ble: ble,
      now: now,
      startTicker: false,
      reintentos: reintentos,
      cache: cache,
    );
  }
}

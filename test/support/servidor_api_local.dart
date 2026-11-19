// P13-14 · Servidor HTTP LOCAL (dart:io, 127.0.0.1, puerto aleatorio) que imita
// el contrato de la API NestJS de CEOSMOS para las pruebas de integración.
//
// A diferencia de `fake_ceosmos_api.dart` (MockClient, sin red), aquí la app usa su
// cliente HTTP real: sockets, cabeceras, JSON y códigos de estado viajan de verdad.
// Nunca se contacta producción (Vercel/Neon): todo vive en la memoria de la prueba.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

class PeticionRegistrada {
  PeticionRegistrada(this.metodo, this.ruta, this.cabeceras, this.cuerpo);
  final String metodo, ruta;
  final Map<String, String> cabeceras;
  final Object? cuerpo;
}

class ServidorApiLocal {
  ServidorApiLocal._(this._servidor);

  final HttpServer _servidor;
  final peticiones = <PeticionRegistrada>[];

  /// correo → {id, username, password, verified}
  final usuarios = <String, Map<String, Object>>{};
  final _tokens = <String, String>{}; // token → correo
  final _dispositivos = <String, Map<String, Object?>>{}; // id → dispositivo (con dueño)
  int _seq = 0;

  /// Si es true el servidor acepta la conexión pero nunca responde (prueba de tiempo límite).
  bool colgado = false;

  String get baseUrl => 'http://${_servidor.address.address}:${_servidor.port}/api';

  static Future<ServidorApiLocal> iniciar() async {
    final s = ServidorApiLocal._(await HttpServer.bind(InternetAddress.loopbackIPv4, 0));
    s._servidor.listen(s._atender);
    return s;
  }

  Future<void> cerrar() => _servidor.close(force: true);

  void agregarUsuario(String correo, String password, {String username = 'ana', bool verificado = true}) {
    usuarios[correo] = {'id': 'u${++_seq}', 'username': username, 'password': password, 'verified': verificado};
  }

  Future<void> _atender(HttpRequest req) async {
    final texto = await utf8.decodeStream(req);
    Object? cuerpo;
    try {
      cuerpo = texto.isEmpty ? null : jsonDecode(texto);
    } on FormatException {
      cuerpo = texto;
    }
    final cabeceras = <String, String>{};
    req.headers.forEach((k, v) => cabeceras[k] = v.join(','));
    peticiones.add(PeticionRegistrada(req.method, req.uri.path, cabeceras, cuerpo));
    if (colgado) return; // sin respuesta: el cliente debe aplicar su tiempo límite

    final (estado, respuesta) = _responder(req.method, req.uri.path.replaceFirst('/api', ''), cabeceras, cuerpo);
    req.response
      ..statusCode = estado
      ..headers.contentType = ContentType.json;
    if (respuesta != null) req.response.write(jsonEncode(respuesta));
    await req.response.close();
  }

  (int, Object?) _error(int estado, String mensaje) =>
      (estado, {'statusCode': estado, 'message': mensaje, 'error': 'ERROR'});

  (int, Object?) _responder(String metodo, String ruta, Map<String, String> cab, Object? cuerpo) {
    final b = cuerpo is Map ? cuerpo : const {};
    switch ((metodo, ruta)) {
      case ('POST', '/auth/register'):
        final correo = '${b['email'] ?? ''}';
        final pass = '${b['password'] ?? ''}';
        if (!correo.contains('@') || pass.length < 8) {
          return _error(400, 'email must be an email');
        }
        if (usuarios.containsKey(correo)) return _error(409, 'Email already in use');
        agregarUsuario(correo, pass, username: '${b['username']}', verificado: false);
        return (201, {'message': 'Registered. Check your email.'});
      case ('POST', '/auth/login'):
        final u = usuarios['${b['email']}'];
        if (u == null || u['password'] != b['password']) return _error(401, 'Invalid credentials');
        if (u['verified'] != true) return _error(401, 'Email not verified');
        final token = 'tok-${++_seq}';
        _tokens[token] = '${b['email']}';
        return (200, {'token': token});
    }
    // Rutas protegidas: exigen `Authorization: Bearer <token>` válido.
    final correo = _tokens[(cab['authorization'] ?? '').replaceFirst('Bearer ', '')];
    if (correo == null) return _error(401, 'Unauthorized');
    final u = usuarios[correo]!;
    switch ((metodo, ruta)) {
      case ('GET', '/users/me'):
        return (200, {'id': u['id'], 'email': correo, 'username': u['username'], 'role': 'USER', 'emailVerified': true});
      case ('POST', '/devices'):
        final d = {
          'id': 'd${++_seq}',
          'name': b['name'],
          'type': b['type'] ?? 'WEARABLE',
          'transport': b['transport'] ?? 'BLE',
          'address': b['address'],
          'lastSeenAt': null,
          '_owner': correo,
        };
        _dispositivos[d['id'] as String] = d;
        return (201, Map.of(d)..remove('_owner'));
      case ('GET', '/devices'):
        return (200, [
          for (final d in _dispositivos.values.where((d) => d['_owner'] == correo)) Map.of(d)..remove('_owner'),
        ]);
    }
    if (metodo == 'DELETE' && ruta.startsWith('/devices/')) {
      final d = _dispositivos[ruta.substring('/devices/'.length)];
      // Como la API: un recurso ajeno responde 404 (no revela que existe; IDOR).
      if (d == null || d['_owner'] != correo) return _error(404, 'Device not found');
      _dispositivos.remove(d['id']);
      return (200, {'success': true});
    }
    return _error(404, 'Cannot $metodo $ruta');
  }
}

/// Un puerto local donde nadie escucha (conexión rechazada).
Future<int> puertoCerrado() async {
  final s = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final p = s.port;
  await s.close();
  return p;
}

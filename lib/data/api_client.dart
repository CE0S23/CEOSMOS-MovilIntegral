import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Error de la API de CEOSMOS con un mensaje listo para mostrarse.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  bool get unauthorized => statusCode == 401;
  @override
  String toString() => message;
}

/// Cliente HTTP único de la API de CEOSMOS (NestJS). Envía el JWT como
/// `Authorization: Bearer`, aplica tiempo límite y traduce los errores.
class ApiClient {
  ApiClient({
    required this.baseUrl,
    http.Client? client,
    this.timeout = const Duration(seconds: 15),
  }) : _http = client ?? http.Client();

  final String baseUrl;
  final Duration timeout;
  final http.Client _http;

  /// Token de la sesión actual (lo fija el repositorio de autenticación).
  String? token;

  /// Se invoca cuando el servidor rechaza el token (sesión vencida o revocada).
  void Function()? onUnauthorized;

  Future<dynamic> get(String path, {Map<String, String>? query}) =>
      _send('GET', path, query: query);
  Future<dynamic> post(String path, [Object? body]) => _send('POST', path, body: body);
  Future<dynamic> put(String path, [Object? body]) => _send('PUT', path, body: body);
  Future<dynamic> patch(String path, [Object? body]) => _send('PATCH', path, body: body);
  Future<dynamic> delete(String path) => _send('DELETE', path);

  Future<dynamic> _send(
    String method,
    String path, {
    Object? body,
    Map<String, String>? query,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final request = http.Request(method, uri)
      ..headers['Accept'] = 'application/json';
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    final http.Response response;
    try {
      // P12-D03: UN solo plazo para toda la petición. Antes había uno para las
      // cabeceras y otro para el cuerpo: si la red caía a mitad de la respuesta, el
      // error tardaba hasta 2 × 15 s (se midieron 26 s en RES-01).
      response = await (() async => http.Response.fromStream(await _http.send(request)))()
          .timeout(timeout);
    } on TimeoutException {
      throw const ApiException(
        'El servidor de CEOSMOS tardó demasiado en responder. Intenta de nuevo.',
      );
    } on http.ClientException {
      // package:http envuelve los SocketException en ClientException.
      throw const ApiException(
        'No hay conexión con el servidor de CEOSMOS. Revisa tu red.',
      );
    } on Exception catch (e) {
      // Blindaje (22/11): package:http no envuelve los errores de TLS
      // (HandshakeException) ni otros de E/S. Un certificado no confiable
      // (mitmproxy, portal cautivo que intercepta HTTPS) se rechaza y aquí se
      // traduce. Sin dart:io para no romper la compilación web.
      final t = '$e';
      if (t.contains('Handshake') || t.contains('CERTIFICATE') || t.contains('Tls')) {
        throw const ApiException(
          'No se pudo establecer una conexión segura con CEOSMOS. '
          'Si estás en una red pública, abre el navegador para aceptar su '
          'portal o cambia de red.',
        );
      }
      throw const ApiException(
        'No hay conexión con el servidor de CEOSMOS. Revisa tu red.',
      );
    }

    final decoded = _decode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) return decoded;
    if (response.statusCode == 401 && token != null) onUnauthorized?.call();
    throw ApiException(
      traducirError(response.statusCode, decoded),
      statusCode: response.statusCode,
    );
  }

  static dynamic _decode(String body) {
    if (body.trim().isEmpty) return null;
    try {
      return jsonDecode(body);
    } on FormatException {
      return body;
    }
  }

  void close() => _http.close();
}

/// Traduce los mensajes del backend (en inglés) a mensajes para el usuario.
String traducirError(int status, Object? body) {
  final raw = body is Map ? body['message'] : null;
  final message = raw is List ? raw.join(' ') : '${raw ?? ''}';
  final m = message.toLowerCase();
  if (m.contains('invalid credentials') || m.contains('password mismatch')) {
    return 'Correo o contraseña incorrectos.';
  }
  if (m.contains('email not verified')) {
    return 'Tu correo aún no está verificado. Escribe el código que te enviamos.';
  }
  if (m.contains('disabled')) {
    return 'Tu cuenta está desactivada. Contacta a un administrador.';
  }
  if (m.contains('locked') || m.contains('too many') || status == 429) {
    return message.isNotEmpty && status != 429
        ? 'Cuenta bloqueada temporalmente por intentos fallidos. Intenta más tarde.'
        : 'Demasiados intentos. Espera un momento e inténtalo de nuevo.';
  }
  if (m.contains('already saved')) {
    return 'Ese elemento ya está en tu biblioteca.'; // 409 de /media (P11-D05)
  }
  if (m.contains('already in use')) {
    return 'Ese correo o nombre de usuario ya está registrado.';
  }
  if (m.contains('invalid or expired code')) {
    return 'El código es incorrecto o ya venció.';
  }
  if (m.contains('already verified')) return 'Ese correo ya estaba verificado.';
  if (m.contains('user not found')) return 'No encontramos una cuenta con ese correo.';
  if (m.contains('invalid or expired') || m.contains('token')) {
    return status == 401
        ? 'Tu sesión expiró. Vuelve a iniciar sesión.'
        : 'El enlace o código ya no es válido.';
  }
  if (m.contains('password must contain')) {
    return 'La contraseña necesita mayúscula, minúscula, número y símbolo.';
  }
  if (status == 401) return 'Tu sesión expiró. Vuelve a iniciar sesión.';
  if (status == 403) return 'No tienes permiso para esta acción.';
  if (status == 404) return 'No se encontró el recurso solicitado.';
  if (status == 409) return message.isNotEmpty ? message : 'El registro ya existe.';
  if (status >= 500) return 'El servidor de CEOSMOS tuvo un problema. Intenta más tarde.';
  return message.isNotEmpty ? message : 'No se pudo completar la operación.';
}

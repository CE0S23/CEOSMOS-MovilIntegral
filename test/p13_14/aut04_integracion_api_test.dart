// P13-14 · AUT-04 · Integración App ↔ servicio con red REAL (loopback).
// Componentes reales: ApiClient (package:http con sockets), AuthRepository y
// CeosmosRepository, contra `ServidorApiLocal` (dart:io) que imita la API NestJS.
// Se valida la respuesta, el código HTTP (200/201/400/401/404) y lo que viaja por el cable.
import 'package:ceosmos_movil_integral/data/api_client.dart';
import 'package:ceosmos_movil_integral/data/auth_repository.dart';
import 'package:ceosmos_movil_integral/data/ceosmos_repository.dart';
import 'package:ceosmos_movil_integral/data/token_store.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/servidor_api_local.dart';

void main() {
  late ServidorApiLocal servidor;
  late ApiClient api;
  late MemoryTokenStore tokens;
  late AuthRepository auth;
  late CeosmosRepository datos;

  setUp(() async {
    servidor = await ServidorApiLocal.iniciar();
    api = ApiClient(baseUrl: servidor.baseUrl, timeout: const Duration(seconds: 5));
    tokens = MemoryTokenStore();
    auth = AuthRepository(api, tokens);
    datos = CeosmosRepository(api);
  });
  tearDown(() async {
    api.close();
    await servidor.cerrar();
  });

  test('201 registro → 401 sin verificar → 200 login: respuesta válida y token guardado', () async {
    await auth.register(' nuevo ', '  Nuevo@Ceosmos.MX ', 'Orbita#2026');
    final reg = servidor.peticiones.last;
    expect((reg.metodo, reg.ruta), ('POST', '/api/auth/register'));
    expect(reg.cabeceras['content-type'], startsWith('application/json'));
    expect(reg.cuerpo, {'username': 'nuevo', 'email': 'nuevo@ceosmos.mx', 'password': 'Orbita#2026'},
        reason: 'la app normaliza el correo antes de enviarlo');

    await expectLater(
      auth.login('nuevo@ceosmos.mx', 'Orbita#2026'),
      throwsA(isA<ApiException>()
          .having((e) => e.statusCode, 'status', 401)
          .having((e) => e.message, 'mensaje', contains('no está verificado'))),
    );

    servidor.usuarios['nuevo@ceosmos.mx']!['verified'] = true;
    final sesion = await auth.login('NUEVO@ceosmos.mx', 'Orbita#2026');
    expect(sesion.user.email, 'nuevo@ceosmos.mx');
    expect(sesion.user.username, 'nuevo');
    expect(tokens.value, sesion.token);
    final me = servidor.peticiones.last;
    expect((me.metodo, me.ruta), ('GET', '/api/users/me'));
    expect(me.cabeceras['authorization'], 'Bearer ${sesion.token}');
  });

  test('400 validación y 401 credenciales: ApiException con el código y mensaje para el usuario', () async {
    servidor.agregarUsuario('ana@ceosmos.mx', 'Orbita#2026');
    await expectLater(
      auth.register('ana', 'sin-arroba', 'corta'),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 400)),
    );
    await expectLater(
      auth.login('ana@ceosmos.mx', 'Incorrecta#1'),
      throwsA(isA<ApiException>()
          .having((e) => e.statusCode, 'status', 401)
          .having((e) => e.message, 'mensaje', 'Correo o contraseña incorrectos.')),
    );
    expect(tokens.value, isNull, reason: 'un login fallido no deja sesión');
    expect(api.token, isNull);
  });

  test('201 crear dispositivo, 200 listar y 404 al borrar uno ajeno (IDOR)', () async {
    servidor.agregarUsuario('ana@ceosmos.mx', 'Orbita#2026');
    servidor.agregarUsuario('beto@ceosmos.mx', 'Orbita#2026', username: 'beto');
    await auth.login('ana@ceosmos.mx', 'Orbita#2026');
    final reloj = await datos.linkDevice(name: 'Reloj CEOSMOS', address: 'CE:05:AB:01:02:FF', type: 'WEARABLE', transport: 'BLE');
    expect(reloj.id, isNotEmpty);
    expect((await datos.devices()).single.address, 'CE:05:AB:01:02:FF');

    await auth.logout();
    await auth.login('beto@ceosmos.mx', 'Orbita#2026');
    expect(await datos.devices(), isEmpty, reason: 'cada cuenta ve solo lo suyo');
    await expectLater(
      datos.unlinkDevice(reloj.id),
      throwsA(isA<ApiException>()
          .having((e) => e.statusCode, 'status', 404)
          .having((e) => e.message, 'mensaje', 'No se encontró el recurso solicitado.')),
    );
  });

  test('401 con token revocado avisa a la app (cierre de sesión) y ruta inexistente → 404', () async {
    servidor.agregarUsuario('ana@ceosmos.mx', 'Orbita#2026');
    await auth.login('ana@ceosmos.mx', 'Orbita#2026');
    var avisos = 0;
    api.onUnauthorized = () => avisos++;
    api.token = 'token-revocado';
    await expectLater(auth.me(), throwsA(isA<ApiException>().having((e) => e.unauthorized, '401', isTrue)));
    expect(avisos, 1);
    api.token = tokens.value;
    await expectLater(api.get('/no-existe'), throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 404)));
  });
}

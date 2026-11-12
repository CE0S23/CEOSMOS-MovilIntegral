// Práctica 11 · Fase 2 · Método de COMUNICACIÓN con el servicio
// ApiClient._send (lib/data/api_client.dart:42) y AppState.finishSession
// (lib/core/app_state.dart:272), que guarda la sesión o la deja pendiente.
//
// Grafo de _send:
//   D1 token != null          → agrega Authorization
//   D2 body != null           → agrega Content-Type y cuerpo JSON
//   E1 TimeoutException       → ApiException(tiempo)
//   E2 ClientException        → ApiException(sin conexión)
//   D3 200 <= status < 300    → return decoded            (C3a, C3b)
//   D4 status == 401 && token → onUnauthorized()          (C4a, C4b)
//   R  throw ApiException(traducirError)
// V(G) = 8 decisiones atómicas (D1, D2, 2 salidas de excepción, C3a, C3b, C4a, C4b) + 1 = 9.
import 'dart:convert';
import 'dart:io';

import 'package:ceosmos_movil_integral/core/app_state.dart';
import 'package:ceosmos_movil_integral/data/api_client.dart';
import 'package:ceosmos_movil_integral/data/auth_repository.dart';
import 'package:ceosmos_movil_integral/data/catalog.dart';
import 'package:ceosmos_movil_integral/data/ceosmos_repository.dart';
import 'package:ceosmos_movil_integral/data/token_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../support/fake_ceosmos_api.dart';

/// Servidor programable: guarda la última petición y responde lo indicado.
class _Srv {
  http.Request? ultima;
  late int status;
  late String cuerpo;
  Duration demora = Duration.zero;
  ApiClient cliente({String? token, Duration timeout = const Duration(seconds: 2)}) =>
      ApiClient(
        baseUrl: 'http://api.test/api',
        timeout: timeout,
        client: MockClient((r) async {
          ultima = r;
          await Future<void>.delayed(demora);
          return http.Response(cuerpo, status);
        }),
      )..token = token;
}

void main() {
  group('_send: caminos independientes', () {
    final s = _Srv();
    test('CB1 D1=F D2=F D3=V: GET sin token → JSON decodificado, sin Authorization', () async {
      s..status = 200..cuerpo = '{"ok":true}';
      expect(await s.cliente().get('/x'), {'ok': true});
      expect(s.ultima!.headers.containsKey('Authorization'), isFalse);
      expect(s.ultima!.headers['Accept'], 'application/json');
    });
    test('CB2 D1=V D2=V: POST con token y cuerpo → cabeceras y JSON enviados', () async {
      s..status = 201..cuerpo = '{"id":"1"}';
      await s.cliente(token: 'abc').post('/x', {'a': 1});
      expect(s.ultima!.headers['Authorization'], 'Bearer abc');
      expect(s.ultima!.headers['Content-Type'], startsWith('application/json'));
      expect(jsonDecode(s.ultima!.body), {'a': 1});
    });
    test('CB3 204 sin cuerpo → null; cuerpo no JSON → texto (FormatException controlada)', () async {
      s..status = 204..cuerpo = '';
      expect(await s.cliente().delete('/x'), isNull);
      s..status = 200..cuerpo = 'pong';
      expect(await s.cliente().get('/x'), 'pong');
    });
    test('CB4 E1: el servidor no responde a tiempo → ApiException de tiempo', () async {
      s..status = 200..cuerpo = '{}'..demora = const Duration(milliseconds: 300);
      await expectLater(
        s.cliente(timeout: const Duration(milliseconds: 50)).get('/x'),
        throwsA(isA<ApiException>().having((e) => e.message, 'm', contains('tardó demasiado'))),
      );
      s.demora = Duration.zero;
    });
    test('CB5 E2: puerto cerrado real (SocketException → ClientException)', () async {
      final libre = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final port = libre.port;
      await libre.close();
      final api = ApiClient(baseUrl: 'http://127.0.0.1:$port/api');
      addTearDown(api.close);
      await expectLater(
        api.get('/users/me'),
        throwsA(isA<ApiException>()
            .having((e) => e.message, 'm', contains('No hay conexión'))
            .having((e) => e.statusCode, 'status', isNull)),
      );
    });
    test('CB6 D4: C4a=V C4b=V → 401 con token avisa a la app (sesión vencida)', () async {
      var avisos = 0;
      s..status = 401..cuerpo = '{"message":"Unauthorized"}';
      final api = s.cliente(token: 't')..onUnauthorized = () => avisos++;
      await expectLater(api.get('/x'), throwsA(isA<ApiException>().having((e) => e.unauthorized, '401', isTrue)));
      expect(avisos, 1);
    });
    test('CB7 D4: C4a=V C4b=F → 401 sin token (login fallido) NO cierra sesión', () async {
      var avisos = 0;
      s..status = 401..cuerpo = '{"message":"Invalid credentials"}';
      final api = s.cliente()..onUnauthorized = () => avisos++;
      await expectLater(api.post('/auth/login', {}), throwsA(isA<ApiException>()));
      expect(avisos, 0);
    });
    test('CB8 D4: C4a=F → 500 lanza error genérico sin filtrar detalles', () async {
      s..status = 500..cuerpo = '{"message":"PrismaClientKnownRequestError at ..."}';
      await expectLater(
        s.cliente(token: 't').get('/x'),
        throwsA(isA<ApiException>().having((e) => e.message, 'm', 'El servidor de CEOSMOS tuvo un problema. Intenta más tarde.')),
      );
    });
    test('Límites de D3 (200 ≤ status < 300): 199, 200, 299 y 300', () async {
      for (final (code, ok) in [(199, false), (200, true), (299, true), (300, false)]) {
        s..status = code..cuerpo = '{}';
        final r = s.cliente().get('/x');
        await (ok ? expectLater(r, completion({})) : expectLater(r, throwsA(isA<ApiException>())));
      }
    });
  });

  group('finishSession: comunicación y pérdida de conexión', () {
    test('Sin red: la sesión queda pendiente, no se muestra como guardada y se envía una sola vez al volver', () async {
      var now = DateTime(2026, 11, 11, 12);
      final api = FakeCeosmosApi();
      final u = api.addUser('r@example.com', 'Clave#2026');
      final st = api.appState(now: () => now);
      addTearDown(st.dispose);
      await st.acceptSession(await st.auth.login('r@example.com', 'Clave#2026'));

      st.startSession(catalog.first, 5);
      now = now.add(const Duration(seconds: 90));
      api.offline = true;
      await st.finishSession();
      expect(st.workspace.history.single.synced, isFalse);
      expect(st.pendingSessions, 1);
      expect(st.takeNotice(), contains('se guardará cuando vuelva la conexión'));
      expect(u.sessions, isEmpty);

      await st.loadWorkspace(); // sigue sin red: no se pierde
      expect(st.pendingSessions, 1);
      expect(st.dataError, contains('No hay conexión'));

      api.offline = false;
      await st.loadWorkspace();
      expect(st.pendingSessions, 0);
      expect(u.sessions, hasLength(1));
      expect(u.sessions.single['durationSeconds'], 90);
      expect(st.workspace.history, hasLength(1));
    });

    test('Rama D0 (media == null): sin sesión activa no envía nada', () async {
      final api = FakeCeosmosApi()..addUser('n@example.com', 'Clave#2026');
      final st = api.appState();
      addTearDown(st.dispose);
      await st.acceptSession(await st.auth.login('n@example.com', 'Clave#2026'));
      final antes = api.calls.length;
      await st.finishSession();
      expect(api.calls.length, antes);
    });

    test('Rama 401 al guardar (sesión revocada): no se encola y vuelve al acceso', () async {
      var now = DateTime(2026, 11, 11, 12);
      final api = FakeCeosmosApi();
      final u = api.addUser('v@example.com', 'Clave#2026');
      final st = api.appState(now: () => now);
      addTearDown(st.dispose);
      await st.acceptSession(await st.auth.login('v@example.com', 'Clave#2026'));
      st.startSession(catalog.first, 5);
      now = now.add(const Duration(seconds: 30));
      api.revokeAll(); // login en otro dispositivo
      await st.finishSession();
      expect(st.pendingSessions, 0);
      expect(st.status, AuthStatus.signedOut);
      expect(st.takeNotice(), contains('expiró'));
      expect(u.sessions, isEmpty);
    });

    test('P11-D01 CORREGIDO: si se pierde la RESPUESTA (el servidor sí guardó), el reintento NO duplica la sesión', () async {
      var now = DateTime(2026, 11, 11, 12);
      final api = FakeCeosmosApi();
      final u = api.addUser('d@example.com', 'Clave#2026');
      var perderRespuesta = false;
      final cliente = MockClient((req) async {
        final r = await api.client.send(http.Request(req.method, req.url)
          ..headers.addAll(req.headers)
          ..body = req.body);
        final res = await http.Response.fromStream(r);
        if (perderRespuesta && req.method == 'POST' && req.url.path.endsWith('/focus-sessions')) {
          throw http.ClientException('Connection reset by peer'); // llegó al servidor
        }
        return res;
      });
      final http0 = ApiClient(baseUrl: 'http://api.test/api', client: cliente);
      final st = AppState(
        auth: AuthRepository(http0, MemoryTokenStore()),
        data: CeosmosRepository(http0),
        now: () => now,
        startTicker: false,
      );
      addTearDown(st.dispose);
      await st.acceptSession(await st.auth.login('d@example.com', 'Clave#2026'));

      st.startSession(catalog.first, 5);
      now = now.add(const Duration(seconds: 60));
      perderRespuesta = true;
      await st.finishSession();
      expect(st.pendingSessions, 1); // la app cree que no se guardó
      expect(u.sessions, hasLength(1)); // pero el servidor ya la tiene

      final clientId = u.sessions.single['clientId'] as String;
      expect(clientId, matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')));

      perderRespuesta = false;
      await st.loadWorkspace(); // reintento automático con el MISMO clientId
      // Antes de la corrección quedaban 2 filas idénticas; ahora el servidor
      // reconoce el clientId y devuelve la sesión que ya tenía.
      expect(u.sessions, hasLength(1));
      expect(st.pendingSessions, 0);
      expect(st.workspace.history.where((h) => h.clientId == clientId), hasLength(1));
      expect(st.workspace.history.first.synced, isTrue);
    });
  });
}

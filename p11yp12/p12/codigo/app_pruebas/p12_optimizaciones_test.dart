// Práctica 12 · Pruebas de las optimizaciones y correcciones de la app:
//   P12-O1 historial paginado + totales del servidor
//   P12-O2 el tic del temporizador ya no notifica a todo AppState
//   P12-O3 reintento con espera exponencial, sin envíos ni cargas duplicadas
//   P12-D02 una sesión pendiente rechazada (4xx) ya no bloquea la carga de datos
import 'dart:math';

import 'package:ceosmos_movil_integral/core/app_state.dart';
import 'package:ceosmos_movil_integral/core/reintentos.dart';
import 'package:ceosmos_movil_integral/data/api_client.dart';
import 'package:ceosmos_movil_integral/data/catalog.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_ceosmos_api.dart';

/// Política rápida y sin variación para pruebas: 20, 40, 80… ms.
const _rapida = PoliticaReintento(base: Duration(milliseconds: 20), maximo: Duration(milliseconds: 200), variacion: 0);

Future<AppState> _entrar(FakeCeosmosApi api, {DateTime Function()? now, PoliticaReintento p = _rapida}) async {
  final st = api.appState(now: now, reintentos: p);
  addTearDown(st.dispose);
  await st.acceptSession(await st.auth.login('a@example.com', 'Clave#2026'));
  return st;
}

void main() {
  group('PoliticaReintento (P12-O3)', () {
    test('espera exponencial 2, 4, 8, 16, 32 s y tope de 60 s', () {
      const p = PoliticaReintento(variacion: 0);
      expect([for (var i = 0; i < 8; i++) p.espera(i).inSeconds], [2, 4, 8, 16, 32, 60, 60, 60]);
    });

    test('la variación aleatoria queda dentro de ±20 %', () {
      final p = PoliticaReintento(azar: Random(7));
      for (var i = 0; i < 200; i++) {
        final ms = p.espera(2).inMilliseconds; // 8 s ± 20 %
        expect(ms, inInclusiveRange(6400, 9600));
      }
    });

    test('solo se reintenta lo que puede salir bien después', () {
      bool r(int? s) => PoliticaReintento.reintentable(ApiException('x', statusCode: s));
      expect([r(null), r(408), r(429), r(500), r(502), r(503)], everyElement(isTrue));
      expect([r(400), r(401), r(403), r(404), r(409), r(413)], everyElement(isFalse));
    });
  });

  group('Reintento automático de escrituras (P12-O3)', () {
    test('sin red la sesión queda pendiente y se envía SOLA al volver, con el mismo clientId', () async {
      final api = FakeCeosmosApi();
      final u = api.addUser('a@example.com', 'Clave#2026');
      final st = await _entrar(api);
      st.startSession(catalog.first, 5);
      api.offline = true;
      await st.finishSession();
      expect(st.pendingSessions, 1);
      expect(st.retryScheduled, isTrue);
      final clientId = st.workspace.history.first.clientId;

      await Future<void>.delayed(const Duration(milliseconds: 70)); // 20 + 40 ms: 2 fallos
      expect(st.pendingSessions, 1);
      api.offline = false;
      await Future<void>.delayed(const Duration(milliseconds: 250));
      expect(st.pendingSessions, 0, reason: 'el reintento automático la envió');
      expect(u.sessions, hasLength(1));
      expect(u.sessions.single['clientId'], clientId);
      expect(st.workspace.history.single.synced, isTrue);
      expect(st.retryScheduled, isFalse);
    });

    test('la respuesta perdida no duplica: el reintento lleva el mismo clientId', () async {
      final api = FakeCeosmosApi();
      final u = api.addUser('a@example.com', 'Clave#2026');
      final st = await _entrar(api);
      st.startSession(catalog.first, 5);
      // Se simula que el servidor ya la guardó pero la respuesta no llegó.
      api.offline = true;
      await st.finishSession();
      u.sessions.add({...st.workspace.history.first.toJson(), 'id': 'ya-guardada'});
      api.offline = false;
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(u.sessions, hasLength(1));
      expect(st.workspace.history.where((s) => s.clientId == u.sessions.single['clientId']), hasLength(1));
    });

    test('al cerrar sesión se cancela el reintento programado', () async {
      final api = FakeCeosmosApi()..addUser('a@example.com', 'Clave#2026');
      final st = await _entrar(api, p: const PoliticaReintento(variacion: 0));
      st.startSession(catalog.first, 5);
      api.offline = true;
      await st.finishSession();
      expect(st.retryScheduled, isTrue);
      api.offline = false;
      await st.signOut();
      expect(st.retryScheduled, isFalse);
      expect(st.pendingSessions, 0);
    });
  });

  group('Pendiente rechazada de forma definitiva (P12-D02)', () {
    test('un 400 al reintentar descarta esa sesión y los datos se cargan', () async {
      final api = FakeCeosmosApi();
      final u = api.addUser('a@example.com', 'Clave#2026');
      final st = await _entrar(api, p: const PoliticaReintento(variacion: 0)); // 2 s: no interfiere
      st.startSession(catalog.first, 5);
      api.offline = true;
      await st.finishSession();
      expect(st.pendingSessions, 1);
      api
        ..offline = false
        ..rechazarSesiones = true;
      u.favorites.add('orbit');
      await st.loadWorkspace();
      expect(st.dataError, isNull, reason: 'antes de P12-D02 la carga fallaba siempre');
      expect(st.workspace.favorites, contains('orbit'));
      expect(st.pendingSessions, 0);
      expect(st.takeNotice(), contains('no acepta'));
    });

    test('un 400 en el primer envío no se encola ni se muestra como guardada', () async {
      final api = FakeCeosmosApi()
        ..addUser('a@example.com', 'Clave#2026')
        ..rechazarSesiones = true;
      final st = await _entrar(api);
      st.startSession(catalog.first, 5);
      await st.finishSession();
      expect(st.pendingSessions, 0);
      expect(st.workspace.history, isEmpty);
      expect(st.takeNotice(), contains('no aceptó'));
    });
  });

  group('Sin operaciones duplicadas ante respuestas tardías (P12-O3, RES-08)', () {
    test('dos recargas simultáneas hacen UNA sola ronda de peticiones', () async {
      final api = FakeCeosmosApi()..addUser('a@example.com', 'Clave#2026');
      final st = await _entrar(api);
      api.calls.clear();
      await Future.wait([st.loadWorkspace(), st.loadWorkspace(), st.loadWorkspace()]);
      expect(api.calls.where((c) => c == 'GET /favorites'), hasLength(1));
      expect(api.calls.where((c) => c == 'GET /focus-sessions'), hasLength(1));
    });

    test('una pendiente no se envía dos veces aunque coincidan dos recargas', () async {
      final api = FakeCeosmosApi();
      final u = api.addUser('a@example.com', 'Clave#2026');
      final st = await _entrar(api, p: const PoliticaReintento(variacion: 0));
      st.startSession(catalog.first, 5);
      api.offline = true;
      await st.finishSession();
      api
        ..offline = false
        ..calls.clear();
      await Future.wait([st.loadWorkspace(), st.loadWorkspace()]);
      expect(api.calls.where((c) => c == 'POST /focus-sessions'), hasLength(1));
      expect(u.sessions, hasLength(1));
    });

    test('doble pulsación de «Terminar» envía una sola sesión', () async {
      final api = FakeCeosmosApi();
      final u = api.addUser('a@example.com', 'Clave#2026');
      final st = await _entrar(api);
      st.startSession(catalog.first, 5);
      await Future.wait([st.finishSession(), st.finishSession()]);
      expect(u.sessions, hasLength(1));
    });
  });

  group('Historial paginado y totales del servidor (P12-O1)', () {
    test('primera página de 20, «ver más» por cursor y totales de las 45', () async {
      final api = FakeCeosmosApi();
      final u = api.addUser('a@example.com', 'Clave#2026');
      for (var i = 0; i < 45; i++) {
        final ini = DateTime.utc(2026, 11, 1).add(Duration(hours: i));
        u.sessions.add({
          'id': 'fs-h$i', 'contentKey': 'orbit', 'mode': 'FOCUS',
          'startedAt': ini.toIso8601String(), 'endedAt': ini.add(const Duration(minutes: 5)).toIso8601String(),
          'durationSeconds': 300, 'targetMinutes': 5, 'completed': true,
        });
      }
      final st = await _entrar(api);
      expect(st.workspace.history, hasLength(20));
      expect(st.workspace.history.first.id, 'fs-h44', reason: 'la más reciente primero');
      expect(st.historyHasMore, isTrue);
      expect(st.totalSessions, 45);
      expect(st.totalMinutes, 225, reason: 'antes se sumaban solo las descargadas');

      await st.loadMoreHistory();
      expect(st.workspace.history, hasLength(40));
      await st.loadMoreHistory();
      expect(st.workspace.history, hasLength(45));
      expect(st.historyHasMore, isFalse);
      final ids = st.workspace.history.map((s) => s.id).toSet();
      expect(ids, hasLength(45), reason: 'sin duplicados entre páginas');
    });

    test('guardar una sesión actualiza los totales sin pedirlos de nuevo', () async {
      var now = DateTime(2026, 11, 12, 10);
      final api = FakeCeosmosApi()..addUser('a@example.com', 'Clave#2026');
      final st = await _entrar(api, now: () => now);
      st.startSession(catalog.first, 5);
      now = now.add(const Duration(minutes: 3));
      await st.finishSession();
      expect(st.totalSessions, 1);
      expect(st.totalMinutes, 3);
    });
  });

  group('Temporizador (P12-O2)', () {
    test('el tic avisa solo al reloj, no a todo AppState', () async {
      var now = DateTime(2026, 11, 12, 10);
      final api = FakeCeosmosApi()..addUser('a@example.com', 'Clave#2026');
      final st = await _entrar(api, now: () => now);
      st.startSession(catalog.first, 25);
      var global = 0, reloj = 0;
      st.addListener(() => global++);
      st.reloj.addListener(() => reloj++);
      for (var i = 0; i < 10; i++) {
        now = now.add(const Duration(seconds: 1));
        st.tick();
      }
      expect(reloj, 10);
      expect(global, 0, reason: 'antes: 10 reconstrucciones de toda la pantalla');
      expect(st.remaining, const Duration(minutes: 24, seconds: 50));
    });

    test('al llegar a cero la sesión se guarda y sí se notifica el cambio de estado', () async {
      var now = DateTime(2026, 11, 12, 10);
      final api = FakeCeosmosApi();
      final u = api.addUser('a@example.com', 'Clave#2026');
      final st = await _entrar(api, now: () => now);
      st.startSession(catalog.first, 5);
      var global = 0;
      st.addListener(() => global++);
      now = now.add(const Duration(minutes: 5));
      st.tick();
      await pumpEventQueue();
      expect(st.hasSession, isFalse);
      expect(u.sessions.single['completed'], isTrue);
      expect(global, greaterThan(0));
    });
  });
}

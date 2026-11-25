// Modo sin conexión (PWA instalada o teléfono sin datos): abrir con el perfil guardado,
// no perder sesiones terminadas sin red y recuperarse solo cuando vuelve la conexión.
import 'package:ceosmos_movil_integral/core/app_state.dart';
import 'package:ceosmos_movil_integral/core/reintentos.dart';
import 'package:ceosmos_movil_integral/data/api_client.dart';
import 'package:ceosmos_movil_integral/data/cache_sin_conexion.dart';
import 'package:ceosmos_movil_integral/data/catalog.dart';
import 'package:ceosmos_movil_integral/data/token_store.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_ceosmos_api.dart';

void main() {
  const rapido = PoliticaReintento(base: Duration(milliseconds: 5), maximo: Duration(milliseconds: 20));

  test('ApiException distingue «sin red» de un error del servidor', () async {
    final api = FakeCeosmosApi()..offline = true;
    final state = api.appState();
    addTearDown(state.dispose);
    await expectLater(
      state.auth.login('a@example.com', 'Clave#2026'),
      throwsA(isA<ApiException>().having((e) => e.sinRed, 'sinRed', isTrue)),
    );
    api.offline = false;
    await expectLater(
      state.auth.login('nadie@example.com', 'Clave#2026'),
      throwsA(isA<ApiException>().having((e) => e.sinRed, 'sinRed', isFalse)),
    );
  });

  test('Sin red y con perfil guardado entra en modo sin conexión; sin perfil pide iniciar sesión', () async {
    final api = FakeCeosmosApi()..addUser('a@example.com', 'Clave#2026', username: 'ana');
    final tokens = MemoryTokenStore();
    final cache = CacheEnMemoria();
    final primero = api.appState(tokens: tokens, cache: cache);
    await primero.acceptSession(await primero.auth.login('a@example.com', 'Clave#2026'));
    await primero.setPreferredMinutes(45);
    await pumpEventQueue();
    primero.dispose();
    expect(cache.perfil, isNot(contains('Clave')), reason: 'nunca se guarda la contraseña');
    expect(cache.perfil, isNot(contains(tokens.value!)), reason: 'el token vive en el almacén seguro');

    api.offline = true;
    final segundo = api.appState(tokens: tokens, cache: cache);
    addTearDown(segundo.dispose);
    await segundo.restore();
    expect(segundo.status, AuthStatus.signedIn);
    expect(segundo.sinConexion, isTrue);
    expect(segundo.user!.username, 'ana');
    expect(segundo.targetMinutes, 45);
    expect(segundo.dataError, contains('Sin conexión'));

    final sinPerfil = api.appState(tokens: tokens, cache: CacheEnMemoria());
    addTearDown(sinPerfil.dispose);
    await sinPerfil.restore();
    expect(sinPerfil.status, AuthStatus.signedOut);
    expect(tokens.value, isNotNull, reason: 'sin red no se borra el token');
  });

  test('Una sesión terminada sin red sobrevive al cierre de la app y se envía una sola vez', () async {
    final api = FakeCeosmosApi();
    final user = api.addUser('a@example.com', 'Clave#2026');
    final tokens = MemoryTokenStore();
    final cache = CacheEnMemoria();
    final primero = api.appState(tokens: tokens, cache: cache);
    await primero.acceptSession(await primero.auth.login('a@example.com', 'Clave#2026'));
    primero.startSession(catalog.first, 5);
    api.offline = true;
    await primero.finishSession();
    await pumpEventQueue();
    expect(primero.pendingSessions, 1);
    primero.dispose(); // se cierra la app sin red

    final segundo = api.appState(tokens: tokens, cache: cache);
    addTearDown(segundo.dispose);
    await segundo.restore();
    expect(segundo.sinConexion, isTrue);
    expect(segundo.pendingSessions, 1);
    expect(segundo.workspace.history.single.synced, isFalse);

    api.offline = false;
    await segundo.loadWorkspace();
    await pumpEventQueue();
    expect(segundo.sinConexion, isFalse);
    expect(segundo.pendingSessions, 0);
    expect(user.sessions, hasLength(1));
    expect(await cache.leerPendientes(segundo.user!.id), isEmpty);
  });

  test('Al volver la red se reconecta solo, sin que el usuario haga nada', () async {
    final api = FakeCeosmosApi()..addUser('a@example.com', 'Clave#2026');
    final tokens = MemoryTokenStore();
    final cache = CacheEnMemoria();
    final primero = api.appState(tokens: tokens, cache: cache);
    await primero.acceptSession(await primero.auth.login('a@example.com', 'Clave#2026'));
    primero.dispose();

    api.offline = true;
    final state = api.appState(tokens: tokens, cache: cache, reintentos: rapido);
    addTearDown(state.dispose);
    await state.restore();
    expect(state.sinConexion, isTrue);
    api.offline = false;
    for (var i = 0; i < 50 && state.sinConexion; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(state.sinConexion, isFalse);
    expect(state.dataError, isNull);
  });

  test('Token revocado mientras estaba sin conexión: al volver la red se cierra la sesión', () async {
    final api = FakeCeosmosApi()..addUser('a@example.com', 'Clave#2026');
    final tokens = MemoryTokenStore();
    final cache = CacheEnMemoria();
    final primero = api.appState(tokens: tokens, cache: cache);
    await primero.acceptSession(await primero.auth.login('a@example.com', 'Clave#2026'));
    primero.dispose();

    api.offline = true;
    final state = api.appState(tokens: tokens, cache: cache);
    addTearDown(state.dispose);
    await state.restore();
    expect(state.status, AuthStatus.signedIn);
    api
      ..offline = false
      ..revokeAll();
    await state.loadWorkspace();
    await pumpEventQueue();
    expect(state.status, AuthStatus.signedOut);
    expect(cache.perfil, isNull, reason: 'cerrar sesión borra la copia local');
  });

  test('Cerrar sesión borra el perfil y los pendientes guardados', () async {
    final api = FakeCeosmosApi()..addUser('a@example.com', 'Clave#2026');
    final cache = CacheEnMemoria();
    final state = api.appState(cache: cache);
    addTearDown(state.dispose);
    await state.acceptSession(await state.auth.login('a@example.com', 'Clave#2026'));
    await pumpEventQueue();
    expect(cache.perfil, isNotNull);
    await state.signOut();
    await pumpEventQueue();
    expect(cache.perfil, isNull);
    expect(cache.pendientes, isEmpty);
  });
}

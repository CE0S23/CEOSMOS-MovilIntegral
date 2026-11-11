import 'dart:convert';
import 'dart:io';

import 'package:ceosmos_movil_integral/core/app_state.dart';
import 'package:ceosmos_movil_integral/core/media_cache_io.dart';
import 'package:ceosmos_movil_integral/core/wearable.dart';
import 'package:ceosmos_movil_integral/data/api_client.dart';
import 'package:ceosmos_movil_integral/data/auth_repository.dart';
import 'package:ceosmos_movil_integral/data/catalog.dart';
import 'package:ceosmos_movil_integral/data/token_store.dart';
import 'package:ceosmos_movil_integral/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'support/fake_ceosmos_api.dart';

void main() {
  test('Login real: normaliza el correo, guarda el token y traduce errores', () async {
    final api = FakeCeosmosApi()..addUser('cesar@example.com', 'Clave#2026', username: 'cesar');
    final tokens = MemoryTokenStore();
    final state = api.appState(tokens: tokens);
    addTearDown(state.dispose);

    final session = await state.auth.login(' CESAR@example.com ', 'Clave#2026');
    expect(session.user.email, 'cesar@example.com');
    expect(tokens.value, session.token);

    await expectLater(
      state.auth.login('cesar@example.com', 'incorrecta'),
      throwsA(isA<ApiException>().having((e) => e.message, 'mensaje', 'Correo o contraseña incorrectos.')),
    );
    expect(AuthRepository.validarContrasenaNueva('prueba123'), isNotNull);
    expect(AuthRepository.validarContrasenaNueva('Prueba#123'), isNull);
  });

  test('Registro exige verificar el correo antes de entrar', () async {
    final api = FakeCeosmosApi();
    final state = api.appState();
    addTearDown(state.dispose);
    await state.auth.register('nuevo', 'Nuevo@Example.com', 'Clave#2026');
    await expectLater(
      state.auth.login('nuevo@example.com', 'Clave#2026'),
      throwsA(isA<ApiException>().having((e) => e.message, 'mensaje', contains('no está verificado'))),
    );
    await state.auth.verifyEmail('nuevo@example.com', 'a1b2c3');
    expect((await state.auth.login('nuevo@example.com', 'Clave#2026')).user.username, 'nuevo');
  });

  test('El temporizador excluye pausas y guarda una sola sesión completada en el servidor', () async {
    var now = DateTime(2026, 11, 11, 12);
    final api = FakeCeosmosApi();
    final user = api.addUser('a@example.com', 'Clave#2026');
    final state = api.appState(now: () => now);
    addTearDown(state.dispose);
    await state.acceptSession(await state.auth.login('a@example.com', 'Clave#2026'));

    state.startSession(catalog.first, 5);
    now = now.add(const Duration(seconds: 40));
    state.togglePause();
    now = now.add(const Duration(minutes: 10));
    expect(state.elapsed.inSeconds, 40);
    state.togglePause();
    now = now.add(const Duration(minutes: 5));
    state.tick();
    state.tick();
    await pumpEventQueue();
    expect(state.hasSession, isFalse);
    expect(user.sessions, hasLength(1));
    expect(user.sessions.single['durationSeconds'], 300);
    expect(user.sessions.single['completed'], isTrue);
    expect(state.workspace.history.single.synced, isTrue);
  });

  test('Los datos de cada cuenta vienen del servidor y no se mezclan', () async {
    final api = FakeCeosmosApi();
    api.addUser('uno@example.com', 'Clave#2026', username: 'uno');
    api.addUser('dos@example.com', 'Clave#2026', username: 'dos');
    final state = api.appState();
    addTearDown(state.dispose);

    await state.acceptSession(await state.auth.login('uno@example.com', 'Clave#2026'));
    await state.toggleFavorite('orbit');
    await state.setPreferredMinutes(15);
    await state.linkWearable('Banda', '10.0.2.2:5050');
    state.startSession(catalog.first, 5);
    await state.signOut();
    expect(state.hasSession, isFalse);

    await state.acceptSession(await state.auth.login('dos@example.com', 'Clave#2026'));
    expect(state.workspace.favorites, isEmpty);
    expect(state.workspace.history, isEmpty);
    expect(state.workspace.devices, isEmpty);
    await state.signOut();

    await state.acceptSession(await state.auth.login('uno@example.com', 'Clave#2026'));
    expect(state.workspace.favorites, {'orbit'});
    expect(state.workspace.history, hasLength(1));
    expect(state.workspace.devices.single.address, '10.0.2.2:5050');
    expect(state.workspace.preferredMinutes, 15);
  });

  test('Un 401 del servidor cierra la sesión y descarta la actividad', () async {
    final api = FakeCeosmosApi()..addUser('a@example.com', 'Clave#2026');
    final tokens = MemoryTokenStore();
    final state = api.appState(tokens: tokens);
    addTearDown(state.dispose);
    await state.acceptSession(await state.auth.login('a@example.com', 'Clave#2026'));
    state.startSession(catalog.first, 25);
    api.revokeAll();
    await state.loadWorkspace();
    expect(state.user, isNull);
    expect(state.status, AuthStatus.signedOut);
    expect(state.hasSession, isFalse);
    expect(state.notice, contains('sesión expiró'));
    expect(tokens.value, isNull);
  });

  test('Restaurar sesión: token válido entra, token revocado se borra', () async {
    final api = FakeCeosmosApi()..addUser('a@example.com', 'Clave#2026');
    final tokens = MemoryTokenStore();
    final primero = api.appState(tokens: tokens);
    await primero.auth.login('a@example.com', 'Clave#2026');
    primero.dispose();

    final segundo = api.appState(tokens: tokens);
    addTearDown(segundo.dispose);
    await segundo.restore();
    expect(segundo.status, AuthStatus.signedIn);

    api.revokeAll();
    final tercero = api.appState(tokens: tokens);
    addTearDown(tercero.dispose);
    await tercero.restore();
    expect(tercero.status, AuthStatus.signedOut);
    expect(tokens.value, isNull);
  });

  test('Sin red la sesión de enfoque queda pendiente y se envía después', () async {
    final api = FakeCeosmosApi();
    final user = api.addUser('a@example.com', 'Clave#2026');
    final state = api.appState();
    addTearDown(state.dispose);
    await state.acceptSession(await state.auth.login('a@example.com', 'Clave#2026'));
    state.startSession(catalog.first, 5);
    api.offline = true;
    await state.finishSession();
    expect(state.pendingSessions, 1);
    expect(state.workspace.history.single.synced, isFalse);
    api.offline = false;
    await state.loadWorkspace();
    expect(state.pendingSessions, 0);
    expect(user.sessions, hasLength(1));
  });

  test('Cambiar de ambiente guarda la sesión anterior; duración inválida no la altera', () async {
    final api = FakeCeosmosApi()..addUser('a@example.com', 'Clave#2026');
    final state = api.appState();
    addTearDown(state.dispose);
    await state.acceptSession(await state.auth.login('a@example.com', 'Clave#2026'));
    state.startSession(catalog.first, 5);
    expect(() => state.startSession(catalog[1], 0), throwsArgumentError);
    expect(state.currentMedia, catalog.first);
    state.startSession(catalog[1], 15);
    await pumpEventQueue();
    expect(state.workspace.history.single.contentKey, catalog.first.id);
    expect(state.currentMedia, catalog[1]);
  });

  test('Búsqueda combina acentos, tipo, modo y favoritos', () {
    expect(filterCatalog(query: 'ORBITA').single.id, 'orbit');
    expect(filterCatalog(mode: FocusMode.relax, kind: MediaKind.audio).single.id, 'forest');
    expect(filterCatalog(favorites: {'nebula'}, kind: MediaKind.audio), isEmpty);
    expect(filterCatalog(query: 'nada-que-exista'), isEmpty);
  });

  test('Wearable por TCP: recibe lecturas reales y las resume para el historial', () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    server.listen((socket) {
      socket.write('${jsonEncode({'hr': 70, 'steps': 10})}\n');
      socket.write('linea-invalida\n');
      socket.write('${jsonEncode({'hr': 400})}\n'); // fuera de rango: se ignora
      socket.write('${jsonEncode({'hr': 80, 'steps': 25})}\n');
    });
    final w = WearableClient();
    addTearDown(w.dispose);
    await w.conectar(deviceId: 'd1', host: '127.0.0.1', port: server.port);
    expect(w.estado, WearableEstado.conectado);
    for (var i = 0; i < 50 && w.muestras.length < 2; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    expect(w.muestras, [70, 80]);
    expect(w.ultima!.steps, 25);
    final resumen = w.resumenSesion()['wearable'] as Map;
    expect(resumen['avgHeartRate'], 75.0);
    expect(resumen['samples'], 2);
    await w.desconectar();
    expect(w.estado, WearableEstado.desconectado);
  });

  test('Wearable apagado: error claro, sin excepción', () async {
    final libre = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final puerto = libre.port;
    await libre.close();
    final w = WearableClient();
    addTearDown(w.dispose);
    await w.conectar(deviceId: 'd1', host: '127.0.0.1', port: puerto);
    expect(w.estado, WearableEstado.error);
    expect(w.error, contains('No se pudo conectar'));
  });

  test('Caché de imágenes: límite de 2 MB, solo JPEG/WebP y reemplazo LRU', () async {
    final dir = await Directory.systemTemp.createTemp('ceosmos_cache_test');
    addTearDown(() => dir.delete(recursive: true));
    final client = MockClient((req) async {
      final kb = int.parse(req.url.queryParameters['kb'] ?? '1');
      final tipo = req.url.queryParameters['tipo'] ?? 'image/jpeg';
      return http.Response.bytes(List.filled(kb * 1024, 1), 200, headers: {'content-type': tipo});
    });
    final cache = DiskMediaCache(maxBytes: 250 * 1024, directorio: () async => dir, client: client);

    await expectLater(cache.imagen('https://x.test/a?kb=3000'), throwsA(anything));
    await expectLater(cache.imagen('https://x.test/a?kb=1&tipo=text/html'), throwsA(anything));

    await cache.imagen('https://x.test/1?kb=100');
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    await cache.imagen('https://x.test/2?kb=100');
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    await cache.imagen('https://x.test/1?kb=100'); // vuelve a usarse: ya no es la menos reciente
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    await cache.imagen('https://x.test/3?kb=100');
    await cache.recortar();
    expect(await cache.tamano(), lessThanOrEqualTo(250 * 1024));
    final pedidas = <String>[];
    final espia = DiskMediaCache(
      maxBytes: 250 * 1024,
      directorio: () async => dir,
      client: MockClient((req) async {
        pedidas.add(req.url.path);
        return http.Response.bytes(List.filled(1024, 1), 200, headers: {'content-type': 'image/jpeg'});
      }),
    );
    await espia.imagen('https://x.test/1?kb=100');
    await espia.imagen('https://x.test/2?kb=100');
    expect(pedidas, ['/2'], reason: 'la imagen 2 era la menos usada y se eliminó');
  });
}

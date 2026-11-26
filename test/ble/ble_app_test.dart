// Caja negra (UI) + integración AppState ↔ BLE con el periférico simulado:
// conectar con PIN, guardar en la cuenta, lecturas del reloj, notificación,
// comandos remotos que pausan/terminan la sesión y resumen BLE en el historial.
import 'package:ceosmos_movil_integral/app.dart';
import 'package:ceosmos_movil_integral/core/ble/ble_protocolo.dart';
import 'package:ceosmos_movil_integral/core/ble/ble_transporte.dart';
import 'package:ceosmos_movil_integral/core/ble/ecosistema_ble.dart';
import 'package:ceosmos_movil_integral/data/catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_ble.dart';
import '../support/fake_ceosmos_api.dart';
import '../widget_test.dart' show mockAudio;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(mockAudio);

  testWidgets('Equipos: conectar reloj con PIN, ver lecturas y enviar notificación', (tester) async {
    tester.view.physicalSize = const Size(420, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final tablet = PerifericoFalso(remoteId: 'AA', id: 'ab0102ff', pin: '482913');
    final radio = TransporteFalso([tablet]);
    final api = FakeCeosmosApi()..addUser('a@example.com', 'Clave#2026', username: 'Ana');
    final state = api.appState(ble: EcosistemaBle(transporte: radio));
    addTearDown(state.dispose);
    await state.acceptSession(await state.auth.login('a@example.com', 'Clave#2026'));
    await tester.pumpWidget(CeosmosApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.devices_other_outlined).last);
    await tester.pumpAndSettle();

    expect(find.text('CEOSMOS Reloj'), findsOneWidget);
    expect(find.text('CEOSMOS TV'), findsOneWidget);
    final conectar = find.descendant(of: find.byKey(const Key('ble-reloj')), matching: find.text('Conectar'));
    await tester.tap(conectar);
    await tester.pumpAndSettle();
    // PIN inválido (valor límite) → validación del diálogo.
    await tester.enterText(find.byType(TextFormField).last, '12345');
    await tester.tap(find.widgetWithText(FilledButton, 'Conectar').last);
    await tester.pumpAndSettle();
    expect(find.text('Escribe los 6 dígitos.'), findsOneWidget);
    // PIN equivocado → se vuelve a pedir.
    await tester.enterText(find.byType(TextFormField).last, '111111');
    await tester.tap(find.widgetWithText(FilledButton, 'Conectar').last);
    await tester.pumpAndSettle();
    expect(find.text('PIN incorrecto, intenta de nuevo'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).last, '482913');
    await tester.tap(find.widgetWithText(FilledButton, 'Conectar').last);
    await tester.pumpAndSettle();
    expect(state.ble[RolBle.reloj].estado, EstadoEnlace.conectado);
    expect(find.text('Conectado'), findsOneWidget);

    // Se guardó en la cuenta como dispositivo BLE (persistencia en la API).
    final guardado = api.users.values.single.devices.single;
    expect(guardado['transport'], 'BLE');
    expect(guardado['type'], 'WEARABLE');
    expect(guardado['address'], 'CE:05:AB:01:02:FF');
    expect(find.textContaining('vinculado a tu cuenta'), findsOneWidget);

    tablet.enviar(RolBle.reloj, {'t': 'hr', 'hr': 77, 'steps': 900});
    await tester.pumpAndSettle();
    expect(find.text('77 bpm · 900 pasos · 1 lectura'), findsOneWidget);

    await tester.tap(find.text('Enviar al reloj'));
    await tester.pumpAndSettle();
    expect(find.text('Escribe un mensaje para el reloj.'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('ble-mensaje')), 'Respira profundo');
    await tester.tap(find.text('Enviar al reloj'));
    await tester.pumpAndSettle();
    expect(tablet.recibidos[RolBle.reloj]!.last, {'t': 'notif', 'msg': 'Respira profundo'});

    await tester.pump(const Duration(seconds: 5)); // se oculta el aviso (SnackBar)
    await tester.pumpAndSettle();
    final desconectar = find.descendant(of: find.byKey(const Key('ble-reloj')), matching: find.text('Desconectar'));
    await tester.ensureVisible(desconectar);
    await tester.pumpAndSettle();
    await tester.tap(desconectar);
    await tester.pumpAndSettle();
    expect(state.ble[RolBle.reloj].estado, EstadoEnlace.desconectado);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('Bluetooth apagado se avisa en Equipos', (tester) async {
    tester.view.physicalSize = const Size(420, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final radio = TransporteFalso([])..estado = AdaptadorBle.apagado;
    final api = FakeCeosmosApi()..addUser('a@example.com', 'Clave#2026', username: 'Ana');
    final state = api.appState(ble: EcosistemaBle(transporte: radio));
    addTearDown(state.dispose);
    await state.acceptSession(await state.auth.login('a@example.com', 'Clave#2026'));
    await tester.pumpWidget(CeosmosApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.devices_other_outlined).last);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ble-apagado')), findsOneWidget);
    await tester.tap(find.text('Encender'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ble-apagado')), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  test('TV y reloj controlan la sesión; el historial guarda el resumen BLE', () async {
    final tablet = PerifericoFalso(remoteId: 'AA', id: 'ab0102ff');
    final api = FakeCeosmosApi()..addUser('a@example.com', 'Clave#2026', username: 'Ana');
    var ahora = DateTime(2026, 11, 18, 10);
    final state = api.appState(ble: EcosistemaBle(transporte: TransporteFalso([tablet])), now: () => ahora);
    addTearDown(state.dispose);
    await state.acceptSession(await state.auth.login('a@example.com', 'Clave#2026'));
    expect(await state.connectBle(RolBle.tv, pin: '123456'), ResultadoConexion.conectado);
    expect(await state.connectBle(RolBle.reloj, pin: '123456'), ResultadoConexion.conectado);
    expect(api.users.values.single.devices.map((d) => d['type']), unorderedEquals(['TV', 'WEARABLE']));

    // Sin sesión, «pausar» no hace nada; «siguiente» inicia el siguiente ambiente.
    tablet.enviar(RolBle.tv, {'t': 'cmd', 'c': 'toggle'});
    await Future<void>.delayed(Duration.zero);
    expect(state.hasSession, isFalse);
    tablet.enviar(RolBle.tv, {'t': 'cmd', 'c': 'next'});
    await Future<void>.delayed(Duration.zero);
    expect(state.currentMedia!.id, catalog.first.id);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(tablet.recibidos[RolBle.tv]!.last['state'], 'running');
    expect(tablet.recibidos[RolBle.tv]!.last['title'], catalog.first.title);
    expect(tablet.recibidos[RolBle.reloj]!.any((m) => m['t'] == 'notif' && '${m['msg']}'.startsWith('Sesión iniciada')), isTrue);

    tablet.enviar(RolBle.reloj, {'t': 'hr', 'hr': 60});
    tablet.enviar(RolBle.reloj, {'t': 'hr', 'hr': 80});
    tablet.enviar(RolBle.reloj, {'t': 'btn', 'a': 'toggle'});
    await Future<void>.delayed(Duration.zero);
    expect(state.running, isFalse);
    expect(state.notice, 'Reloj: sesión en pausa');
    tablet.enviar(RolBle.tv, {'t': 'cmd', 'c': 'toggle'});
    await Future<void>.delayed(Duration.zero);
    expect(state.running, isTrue);

    ahora = ahora.add(const Duration(minutes: 2));
    tablet.enviar(RolBle.tv, {'t': 'cmd', 'c': 'stop'});
    // 1.4.0: todas las escrituras GATT van en una sola cola por enlace (Reloj + TV);
    // se espera por condición y no un tiempo fijo.
    for (var i = 0; i < 200 && tablet.recibidos[RolBle.tv]!.last['state'] != 'idle'; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(state.hasSession, isFalse);
    final guardada = api.users.values.single.sessions.single;
    final w = (guardada['metadata'] as Map)['wearable'] as Map;
    expect(w['transport'], 'BLE');
    expect(w['avgHeartRate'], 70.0);
    expect(tablet.recibidos[RolBle.tv]!.last['state'], 'idle');
    expect(tablet.recibidos[RolBle.reloj]!.last['msg'], startsWith('Sesión terminada · 02:00'));

    // Cerrar sesión de CEOSMOS desconecta Reloj y TV.
    await state.signOut();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(state.ble[RolBle.tv].estado, EstadoEnlace.desconectado);
    expect(tablet.conexion!.cerrada, isTrue);
  });
}

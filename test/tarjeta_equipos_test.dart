// 1.4.0 · Tarjeta «Tu Reloj y TV» de Inicio: estado vacío, datos en vivo, alerta,
// proyección de la TV, sin conexión con el último valor y etiquetas para lector de pantalla.
import 'package:ceosmos_movil_integral/core/app_state.dart';
import 'package:ceosmos_movil_integral/core/ble/ble_protocolo.dart';
import 'package:ceosmos_movil_integral/data/catalog.dart';
import 'package:ceosmos_movil_integral/ui/tarjeta_equipos.dart';
import 'package:ceosmos_movil_integral/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/equipos_demo.dart';
import 'support/fake_ble.dart';
import 'support/fake_ceosmos_api.dart';
import 'widget_test.dart' show mockAudio;

void main() {
  setUp(mockAudio);

  Future<AppState> sesion(FakeCeosmosApi api, {PerifericoFalso? t}) async {
    final state = api.appState(ble: t == null ? null : bleDemo(t));
    await state.acceptSession(await state.auth.login('ana@example.com', 'Clave#2026'));
    return state;
  }

  Widget envolver(AppState state, {VoidCallback? onEquipos}) => MaterialApp(
    theme: CeosmosTema.claro,
    home: Scaffold(
      body: SingleChildScrollView(
        child: TarjetaEquipos(state: state, onEquipos: onEquipos ?? () {}),
      ),
    ),
  );

  testWidgets('sin equipos: estado vacío amable con botón a Equipos', (tester) async {
    final api = FakeCeosmosApi()..addUser('ana@example.com', 'Clave#2026', username: 'Ana');
    final state = await tester.runAsync(() => sesion(api));
    addTearDown(state!.dispose);
    var abierto = false;
    await tester.pumpWidget(envolver(state, onEquipos: () => abierto = true));
    expect(find.text('Tu Reloj y TV'), findsOneWidget);
    expect(find.textContaining('Aún no vinculas'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('ir-equipos')));
    expect(abierto, isTrue);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('conectados: pulso, pasos, actividad, alerta y proyección; en vivo', (tester) async {
    final semantica = tester.ensureSemantics();
    final api = FakeCeosmosApi()..addUser('ana@example.com', 'Clave#2026', username: 'Ana');
    final t = tabletDemo();
    final state = (await tester.runAsync(() async {
      final s = await sesion(api, t: t);
      await poblarEquipos(s, t);
      return s;
    }))!;
    addTearDown(state.dispose);
    await tester.pumpWidget(envolver(state));
    await tester.pump();

    expect(find.text('Conectado'), findsNWidgets(2));
    expect(find.text('172'), findsOneWidget);
    expect(find.text('123456 pasos'), findsOneWidget);
    expect(find.text('Caminando'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    expect(find.textContaining('Pulso muy alto: 192 bpm'), findsOneWidget);
    expect(find.text(catalog.first.title), findsOneWidget);
    expect(find.textContaining('restantes'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'^Pulso simulado 172 latidos por minuto, 123456 pasos, actividad Caminando')), findsOneWidget);
    expect(find.bySemanticsLabel('Reloj: Conectado'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('^La TV proyecta ')), findsOneWidget);

    // En vivo: llega una lectura nueva.
    await tester.runAsync(() async {
      t.enviar(RolBle.reloj, {'t': 'hr', 'hr': 99, 'steps': 123460, 'act': 'reposo'});
      await Future<void>.delayed(const Duration(milliseconds: 10));
    });
    await tester.pump();
    expect(find.text('99'), findsOneWidget);
    expect(find.text('Reposo'), findsOneWidget);

    // «Entendido» descarta la alerta.
    await tester.tap(find.text('Entendido'));
    await tester.pump();
    expect(find.byKey(const ValueKey('alerta-activa')), findsNothing);
    semantica.dispose();
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('sin conexión: conserva el último valor con su hora y ofrece «Conectar»', (tester) async {
    final api = FakeCeosmosApi()..addUser('ana@example.com', 'Clave#2026', username: 'Ana');
    final t = tabletDemo();
    var ahora = DateTime.now();
    final state = (await tester.runAsync(() async {
      final s = await sesion(api, t: t);
      await poblarEquipos(s, t);
      await s.ble.desconectar(RolBle.tv);
      return s;
    }))!;
    addTearDown(state.dispose);
    await tester.pumpWidget(MaterialApp(
      theme: CeosmosTema.claro,
      home: Scaffold(body: SingleChildScrollView(child: TarjetaEquipos(state: state, onEquipos: () {}, ahora: () => ahora))),
    ));
    await tester.pump();
    expect(find.text('Sin conexión'), findsOneWidget);
    expect(find.byKey(const ValueKey('conectar-tv')), findsOneWidget);
    ahora = ahora.add(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('hace'), findsWidgets);
    await tester.pumpWidget(const SizedBox());
  });

  test('textos de tiempo y estados', () {
    final t = DateTime(2026, 11, 26, 10);
    expect(haceCuanto(t, t.add(const Duration(seconds: 2))), 'hace 2 s');
    expect(haceCuanto(t, t.add(const Duration(minutes: 3))), 'hace 3 min');
    expect(haceCuanto(t, t.add(const Duration(hours: 1))), 'hace 1 h');
  });
}

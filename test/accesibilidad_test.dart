import 'package:ceosmos_movil_integral/app.dart';
import 'package:ceosmos_movil_integral/core/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/equipos_demo.dart';
import 'support/fake_ceosmos_api.dart';
import 'widget_test.dart' show mockAudio;

// Blindaje · accesibilidad básica: áreas táctiles ≥ 48 dp, botones con nombre
// para TalkBack y fuente del sistema al máximo (200 %) sin desbordes.
void main() {
  setUp(mockAudio);

  Future<AppState> abrir(WidgetTester tester, {required bool conSesion, double escala = 1}) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = escala;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final api = FakeCeosmosApi()..addUser('ana@example.com', 'Clave#2026', username: 'Ana');
    final tablet = tabletDemo();
    final state = api.appState(ble: bleDemo(tablet));
    addTearDown(state.dispose);
    if (conSesion) {
      await state.acceptSession(await state.auth.login('ana@example.com', 'Clave#2026'));
      // 1.4.0: tarjeta «Tu Reloj y TV» con datos, alerta y proyección.
      await tester.runAsync(() => poblarEquipos(state, tablet));
    } else {
      state.status = AuthStatus.signedOut;
    }
    await tester.pumpWidget(CeosmosApp(state: state));
    await tester.pumpAndSettle();
    return state;
  }

  testWidgets('Acceso: áreas táctiles ≥ 48 dp y botones con nombre', (tester) async {
    final semantica = tester.ensureSemantics();
    await abrir(tester, conSesion: false);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    semantica.dispose();
  });

  testWidgets('Inicio y pestañas: áreas táctiles ≥ 48 dp y botones con nombre', (tester) async {
    final semantica = tester.ensureSemantics();
    await abrir(tester, conSesion: true);
    for (final icono in [Icons.explore_outlined, Icons.person_outline_rounded]) {
      await tester.tap(find.byIcon(icono).last);
      await tester.pumpAndSettle();
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    }
    semantica.dispose();
  });

  for (final conSesion in [false, true]) {
    testWidgets('Fuente al 200 % sin desbordes (${conSesion ? 'inicio' : 'acceso'})', (tester) async {
      await abrir(tester, conSesion: conSesion, escala: 2);
      expect(tester.takeException(), isNull);
      if (conSesion) {
        for (final icono in [Icons.explore_outlined, Icons.person_outline_rounded]) {
          await tester.tap(find.byIcon(icono).last);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
      }
    });
  }
}

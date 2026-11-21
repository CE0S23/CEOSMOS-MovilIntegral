// Reestructura (21/11): las prácticas son funciones de CEOSMOS. Ningún texto
// visible de la navegación puede nombrar la práctica, salvo el contenido del
// botón ⓘ «Referencia académica» (que solo se abre a propósito).
import 'package:ceosmos_movil_integral/app.dart';
import 'package:ceosmos_movil_integral/core/referencias_academicas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_ceosmos_api.dart';
import 'widget_test.dart' show mockAudio;

final _prohibido = RegExp(r'Práctica|Practica|\bP\d{1,2}\b|Examen|Eval\.');

/// Textos visibles en pantalla: Text/RichText y mensajes de Tooltip.
List<String> _textosVisibles(WidgetTester tester) => [
  for (final w in tester.widgetList<Text>(find.byType(Text, skipOffstage: false)))
    w.data ?? w.textSpan?.toPlainText() ?? '',
  for (final w in tester.widgetList<Tooltip>(find.byType(Tooltip, skipOffstage: false)))
    w.message ?? '',
];

void _sinReferencias(WidgetTester tester, String donde) {
  final malos = _textosVisibles(tester).where(_prohibido.hasMatch).toList();
  expect(malos, isEmpty, reason: 'Textos con referencia académica en $donde');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    mockAudio();
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Ninguna pantalla ni función muestra «Práctica», «P#», «Examen» ni «Eval.»', (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final api = FakeCeosmosApi()
      ..addUser('admin@example.com', 'Clave#2026', username: 'Jefa', role: 'ADMIN');
    final state = api.appState();
    addTearDown(state.dispose);
    await state.acceptSession(await state.auth.login('admin@example.com', 'Clave#2026'));
    await tester.pumpWidget(CeosmosApp(state: state));
    await tester.pumpAndSettle();

    final pestanas = {
      'Inicio': Icons.grid_view_rounded,
      'Explorar': Icons.explore_outlined,
      'Mi sesión': Icons.timelapse_rounded,
      'Equipos': Icons.devices_other_outlined,
      'Soporte': Icons.support_agent_outlined,
      'Perfil': Icons.person_outline_rounded,
    };
    for (final MapEntry(key: nombre, value: icono) in pestanas.entries) {
      await tester.tap(find.byIcon(icono).last);
      await tester.pumpAndSettle();
      _sinReferencias(tester, 'la pestaña $nombre');
    }

    // Cada función reubicada está en su sección, con nombre funcional.
    await tester.tap(find.byIcon(Icons.support_agent_outlined).last);
    await tester.pumpAndSettle();
    for (final t in [
      'Tickets y chat interno',
      'Incidencias sin conexión',
      'Reportes e incidencias',
      'Reportes compartidos',
      'Incidencias en tiempo real',
      'Mis incidencias y acceso',
    ]) {
      expect(find.text(t, skipOffstage: false), findsOneWidget, reason: t);
    }
    await tester.tap(find.byIcon(Icons.devices_other_outlined).last);
    await tester.pumpAndSettle();
    expect(find.text('Mensajería entre equipos', skipOffstage: false), findsWidgets);
    await tester.tap(find.byIcon(Icons.person_outline_rounded).last);
    await tester.pumpAndSettle();
    for (final t in ['Seguridad de la cuenta', 'Directorio de alumnos', 'Citas de bienestar', 'Administración']) {
      expect(find.text(t, skipOffstage: false), findsOneWidget, reason: t);
    }

    // Una función abierta: barra «← Soporte · Incidencias sin conexión · ⓘ».
    await tester.tap(find.byIcon(Icons.support_agent_outlined).last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('funcion-examen1')));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextButton, 'Soporte'), findsOneWidget);
    _sinReferencias(tester, 'la función abierta');
    expect(
      find.byKey(const ValueKey('referencia-examen1')),
      mostrarReferenciasAcademicas ? findsOneWidget : findsNothing,
    );
    // Atrás regresa a Soporte (no cierra la app).
    await tester.tap(find.widgetWithText(TextButton, 'Soporte'));
    await tester.pumpAndSettle();
    expect(find.text('Tickets y chat interno'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}

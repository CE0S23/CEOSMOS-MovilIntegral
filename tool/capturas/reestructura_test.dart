// Capturas de la reestructura (no forma parte de la suite ni del CI):
// menú principal, menú del admin y cada función Flutter con su ⓘ abierto.
//
//   flutter test tool/capturas/reestructura_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:ceosmos_movil_integral/app.dart';
import 'package:ceosmos_movil_integral/practicas/registro_practicas.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test/support/fake_ceosmos_api.dart';

final _salida = Directory('evidencias/reestructura');
const _material = 'C:/flutter/flutter/bin/cache/artifacts/material_fonts';

Future<void> _fuente(String familia, List<String> rutas) async {
  final loader = FontLoader(familia);
  for (final r in rutas) {
    final f = File(r);
    if (f.existsSync()) {
      loader.addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
    }
  }
  await loader.load();
}

Future<void> _cargarFuentes() async {
  await _fuente('MaterialIcons', ['$_material/materialicons-regular.otf']);
  await _fuente('Roboto', [
    '$_material/roboto-regular.ttf',
    '$_material/roboto-medium.ttf',
    '$_material/roboto-bold.ttf',
  ]);
  await _fuente('Bricolage Grotesque', [
    'assets/fonts/BricolageGrotesque-Bold.ttf',
    'assets/fonts/BricolageGrotesque-ExtraBold.ttf',
  ]);
  await _fuente('DM Sans', [
    'assets/fonts/DMSans-Regular.ttf',
    'assets/fonts/DMSans-Medium.ttf',
    'assets/fonts/DMSans-Bold.ttf',
  ]);
}

void _mocks() {
  SharedPreferences.setMockInitialValues({});
  final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  for (final c in [
    'xyz.luan/audioplayers.global',
    'xyz.luan/audioplayers.global/events',
    'xyz.luan/audioplayers',
    'mobile_connect/events',
    'mobile_connect/network',
  ]) {
    m.setMockMethodCallHandler(MethodChannel(c), (_) async => null);
  }
}

final _raiz = GlobalKey();

Future<void> _capturar(WidgetTester tester, String nombre) async {
  await tester.pump(const Duration(milliseconds: 500));
  final boundary =
      _raiz.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final ui.Image img = await boundary.toImage(pixelRatio: 2);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    _salida.createSync(recursive: true);
    File('${_salida.path}/$nombre.png')
        .writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

Future<void> _pestana(WidgetTester tester, IconData icono) async {
  await tester.tap(find.byIcon(icono).last);
  await tester.pumpAndSettle();
}

Future<void> _iniciar(WidgetTester tester, {required bool admin}) async {
  tester.view.physicalSize = const Size(412, 915);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final api = FakeCeosmosApi()
    ..addUser('u@example.com', 'Clave#2026',
        username: admin ? 'Jefa' : 'Ana', role: admin ? 'ADMIN' : 'USER');
  final state = api.appState();
  addTearDown(state.dispose);
  await state.acceptSession(await state.auth.login('u@example.com', 'Clave#2026'));
  await tester.pumpWidget(
    RepaintBoundary(key: _raiz, child: CeosmosApp(state: state)),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(_cargarFuentes);
  setUp(_mocks);

  testWidgets('menús', (tester) async {
    await _iniciar(tester, admin: false);
    await _capturar(tester, '01_menu_principal');
    await _pestana(tester, Icons.support_agent_outlined);
    await _capturar(tester, '02_soporte');
    await tester.scrollUntilVisible(find.text('Mis incidencias y acceso'), 200);
    await _capturar(tester, '03_soporte_reportes');
    await _pestana(tester, Icons.devices_other_outlined);
    await tester.scrollUntilVisible(find.byKey(const ValueKey('funcion-p06')), 300);
    await _capturar(tester, '04_equipos_mensajeria');
    await _pestana(tester, Icons.person_outline_rounded);
    await tester.scrollUntilVisible(find.byKey(const ValueKey('funcion-p05')), 300);
    await _capturar(tester, '05_perfil_herramientas');
  });

  testWidgets('menú del admin', (tester) async {
    await _iniciar(tester, admin: true);
    await _pestana(tester, Icons.person_outline_rounded);
    await _capturar(tester, '06_admin_perfil');
  });

  // Funciones Flutter con su ⓘ abierto (las nativas muestran el mismo texto en
  // un diálogo de Android y solo se ven en el teléfono).
  for (final f in practicas.where((p) => p.tipo == TipoPractica.flutter)) {
    testWidgets('función ${f.id}', (tester) async {
      await _iniciar(tester, admin: false);
      final icono = switch (f.seccion) {
        Seccion.equipos => Icons.devices_other_outlined,
        Seccion.perfil => Icons.person_outline_rounded,
        _ => Icons.support_agent_outlined,
      };
      await _pestana(tester, icono);
      final tarjeta = find.byKey(ValueKey('funcion-${f.id}'));
      await tester.scrollUntilVisible(tarjeta, 300);
      await tester.tap(tarjeta);
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.byKey(ValueKey('referencia-${f.id}')));
      await tester.pump(const Duration(milliseconds: 600));
      await _capturar(tester, '10_${f.seccion.name}_${f.id}_referencia');
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });
  }
}

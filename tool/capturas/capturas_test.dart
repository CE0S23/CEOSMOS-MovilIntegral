// Arnés de capturas del rediseño (no forma parte de la suite ni del CI).
// Renderiza las pantallas principales con la API simulada y guarda PNG en
// evidencias/rediseno/<PREFIJO>_<pantalla>[_oscuro].png.
//
//   $env:PREFIJO='despues'; flutter test tool/capturas/capturas_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:ceosmos_movil_integral/app.dart';
import 'package:ceosmos_movil_integral/core/app_state.dart';
import 'package:ceosmos_movil_integral/practicas/practica_host.dart';
import 'package:ceosmos_movil_integral/practicas/registro_practicas.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test/support/fake_ceosmos_api.dart';

final _prefijo = Platform.environment['PREFIJO'] ?? 'despues';
final _salida = Directory('evidencias/rediseno');
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
  await _fuente('Arial', [
    'C:/Windows/Fonts/arial.ttf',
    'C:/Windows/Fonts/arialbd.ttf',
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

void _mockAudio() {
  final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  for (final c in ['mobile_connect/events', 'mobile_connect/network']) {
    m.setMockMethodCallHandler(MethodChannel(c), (_) async => null);
  }
  for (final c in [
    'xyz.luan/audioplayers.global',
    'xyz.luan/audioplayers.global/events',
  ]) {
    m.setMockMethodCallHandler(MethodChannel(c), (_) async => 1);
  }
  m.setMockMethodCallHandler(const MethodChannel('xyz.luan/audioplayers'), (
    call,
  ) async {
    if (call.method == 'create') {
      final id = (call.arguments as Map)['playerId'];
      m.setMockMethodCallHandler(
        MethodChannel('xyz.luan/audioplayers/events/$id'),
        (_) async => null,
      );
    }
    return 1;
  });
}

final _raiz = GlobalKey();

Future<void> _capturar(WidgetTester tester, String nombre) async {
  await tester.pump(const Duration(milliseconds: 400));
  final boundary =
      _raiz.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final ui.Image img = await boundary.toImage(pixelRatio: 2);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    _salida.createSync(recursive: true);
    File(
      '${_salida.path}/${_prefijo}_$nombre.png',
    ).writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

Future<void> _navegar(WidgetTester tester, IconData icono) async {
  await tester.tap(find.byIcon(icono).last);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(_cargarFuentes);
  setUp(_mockAudio);

  for (final oscuro in [false, true]) {
    final sufijo = oscuro ? '_oscuro' : '';
    testWidgets('capturas$sufijo', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.platformBrightnessTestValue = oscuro
          ? Brightness.dark
          : Brightness.light;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      final api = FakeCeosmosApi();
      api.addUser('ana@example.com', 'Clave#2026', username: 'Ana');
      final state = api.appState()..status = AuthStatus.signedOut;
      addTearDown(state.dispose);
      await tester.pumpWidget(
        RepaintBoundary(key: _raiz, child: CeosmosApp(state: state)),
      );
      await tester.pumpAndSettle();
      await _capturar(tester, '01_acceso$sufijo');

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Correo electrónico'),
        'ana@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Contraseña'),
        'Clave#2026',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
      await tester.pumpAndSettle();
      await _capturar(tester, '02_inicio$sufijo');

      await _navegar(tester, Icons.explore_outlined);
      await _capturar(tester, '03_explorar$sufijo');

      await tester.tap(find.text('Órbita tranquila').first);
      await tester.pumpAndSettle();
      await _capturar(tester, '04_elegir_sesion$sufijo');
      await tester.tap(find.text('Comenzar sesión'));
      await tester.pumpAndSettle();
      await _capturar(tester, '05_sesion$sufijo');

      await _navegar(tester, Icons.devices_other_outlined);
      await _capturar(tester, '06_equipos$sufijo');

      await _navegar(tester, Icons.science_outlined);
      await _capturar(tester, '07_practicas$sufijo');

      await _navegar(tester, Icons.person_outline_rounded);
      await _capturar(tester, '08_perfil$sufijo');
    });

    // Prácticas Flutter que arrancan sin servicios externos.
    for (final id in ['p03_04', 'p05', 'p06', 'examen1', 'eval2']) {
      testWidgets('práctica $id$sufijo', (tester) async {
        tester.view.physicalSize = const Size(412, 915);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.platformBrightnessTestValue = oscuro
            ? Brightness.dark
            : Brightness.light;
        addTearDown(tester.view.reset);
        addTearDown(
          tester.platformDispatcher.clearPlatformBrightnessTestValue,
        );
        final p = practicas.firstWhere((e) => e.id == id);
        await tester.pumpWidget(
          RepaintBoundary(
            key: _raiz,
            child: CeosmosApp(
              state: (FakeCeosmosApi()..addUser('a@b.mx', 'Clave#2026'))
                  .appState()
                ..status = AuthStatus.signedOut,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
        nav.push(
          MaterialPageRoute<void>(builder: (_) => PracticaHost(practica: p)),
        );
        await tester.pump(const Duration(seconds: 1));
        await tester.pump(const Duration(seconds: 1));
        await _capturar(tester, '09_practica_$id$sufijo');
      });
    }
  }
}

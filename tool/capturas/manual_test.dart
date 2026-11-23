// Arnés de capturas del Manual de usuario (no forma parte de la suite ni del CI).
// Pantallas sin sesión (acceso, registro, verificación, recuperación y errores)
// con la API simulada; guarda PNG en evidencias/manual/arnes_<pantalla>.png.
//
//   flutter test tool/capturas/manual_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:ceosmos_movil_integral/app.dart';
import 'package:ceosmos_movil_integral/core/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test/support/fake_ceosmos_api.dart';

final _salida = Directory('evidencias/manual');
const _material = 'C:/flutter/flutter/bin/cache/artifacts/material_fonts';

Future<void> _fuente(String familia, List<String> rutas) async {
  final loader = FontLoader(familia);
  for (final r in rutas) {
    final f = File(r);
    if (f.existsSync()) loader.addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
  }
  await loader.load();
}

Future<void> _cargarFuentes() async {
  await _fuente('MaterialIcons', ['$_material/materialicons-regular.otf']);
  await _fuente('Roboto', ['$_material/roboto-regular.ttf', '$_material/roboto-medium.ttf', '$_material/roboto-bold.ttf']);
  await _fuente('Bricolage Grotesque',
      ['assets/fonts/BricolageGrotesque-Bold.ttf', 'assets/fonts/BricolageGrotesque-ExtraBold.ttf']);
  await _fuente('DM Sans',
      ['assets/fonts/DMSans-Regular.ttf', 'assets/fonts/DMSans-Medium.ttf', 'assets/fonts/DMSans-Bold.ttf']);
}

final _raiz = GlobalKey();

Future<void> _capturar(WidgetTester tester, String nombre) async {
  await tester.pump(const Duration(milliseconds: 400));
  final boundary = _raiz.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final ui.Image img = await boundary.toImage(pixelRatio: 2.5);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    _salida.createSync(recursive: true);
    File('${_salida.path}/arnes_$nombre.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

Future<(FakeCeosmosApi, AppState)> _abrir(WidgetTester tester) async {
  tester.view.physicalSize = const Size(412, 915);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  final api = FakeCeosmosApi()..addUser('ana@example.com', 'Clave#2026', username: 'Ana');
  final state = api.appState()..status = AuthStatus.signedOut;
  addTearDown(state.dispose);
  await tester.pumpWidget(RepaintBoundary(key: _raiz, child: CeosmosApp(state: state)));
  await tester.pumpAndSettle();
  return (api, state);
}

Future<void> _escribir(WidgetTester tester, String etiqueta, String texto) =>
    tester.enterText(find.widgetWithText(TextFormField, etiqueta), texto);

Future<void> _boton(WidgetTester tester, String texto) async {
  final f = find.widgetWithText(FilledButton, texto);
  await tester.ensureVisible(f);
  await tester.tap(f);
  await tester.pumpAndSettle();
}

Future<void> _enlace(WidgetTester tester, String texto) async {
  final f = find.text(texto);
  await tester.ensureVisible(f);
  await tester.tap(f);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(_cargarFuentes);

  testWidgets('acceso y error de credenciales', (tester) async {
    await _abrir(tester);
    await _capturar(tester, '01_acceso');
    await _escribir(tester, 'Correo electrónico', 'ana@example.com');
    await _escribir(tester, 'Contraseña', 'Incorrecta#1');
    await _boton(tester, 'Iniciar sesión');
    await _capturar(tester, '02_error_credenciales');
  });

  testWidgets('sin conexión', (tester) async {
    final (api, _) = await _abrir(tester);
    api.offline = true;
    await _escribir(tester, 'Correo electrónico', 'ana@example.com');
    await _escribir(tester, 'Contraseña', 'Clave#2026');
    await _boton(tester, 'Iniciar sesión');
    await _capturar(tester, '03_sin_conexion');
  });

  testWidgets('registro y verificación', (tester) async {
    await _abrir(tester);
    await _enlace(tester, '¿Primera vez? Crea una cuenta');
    await _capturar(tester, '04_registro');
    await _escribir(tester, 'Nombre de usuario', 'Luis');
    await _escribir(tester, 'Correo electrónico', 'luis@example.com');
    await _escribir(tester, 'Contraseña nueva', 'Nueva#2026x');
    await _boton(tester, 'Crear cuenta');
    await _capturar(tester, '05_verificar');
  });

  testWidgets('recuperar contraseña', (tester) async {
    await _abrir(tester);
    await _enlace(tester, 'Olvidé mi contraseña');
    await _capturar(tester, '06_olvide');
    await _escribir(tester, 'Correo electrónico', 'ana@example.com');
    await _boton(tester, 'Enviar enlace');
    await _capturar(tester, '07_restablecer');
  });
}

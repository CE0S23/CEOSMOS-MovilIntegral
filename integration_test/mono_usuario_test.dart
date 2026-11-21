// Blindaje · «Usuario torpe» DENTRO de la app (sustituye a adb monkey).
//
// Toca, escribe, desplaza y retrocede al azar SOLO sobre los widgets de
// CEOSMOS: nunca inyecta eventos al sistema (no baja la barra de estado, no
// cambia el brillo ni bloquea el teléfono). Usa la API simulada y no abre las
// funciones conectadas a Firebase o a servidores externos, así que no puede
// modificar datos reales.
//
//   En el teléfono:  flutter test integration_test/mono_usuario_test.dart -d <serial>
//   En la PC:        flutter test integration_test/mono_usuario_test.dart
//   Más acciones:    --dart-define=MONO_ACCIONES=20000  (semilla: MONO_SEMILLA)
import 'dart:math';

import 'package:ceosmos_movil_integral/app.dart';
import 'package:ceosmos_movil_integral/core/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/support/fake_ceosmos_api.dart';

const _acciones = int.fromEnvironment('MONO_ACCIONES', defaultValue: 20000);
const _semilla = int.fromEnvironment('MONO_SEMILLA', defaultValue: 2111);

const _textos = [
  '', ' ', 'a', '😀😀😀', '<script>alert(1)</script>', "' OR 1=1 --",
  'ñandú ÁÉÍÓÚ', '0', '-5', '999999999999', '12:34', 'correo@', 'x@y.z',
  'Clave#2026', 'texto muy largo texto muy largo texto muy largo texto muy largo texto muy largo texto muy largo texto muy largo',
];

/// Claves de tarjetas que abren funciones con nube o servidores externos.
bool _bloqueado(Element e) {
  var bloqueado = false;
  e.visitAncestorElements((a) {
    final k = a.widget.key;
    if (k is ValueKey && '${k.value}'.startsWith('funcion-')) {
      bloqueado = true;
      return false;
    }
    return true;
  });
  final k = e.widget.key;
  if (k is ValueKey && '${k.value}'.startsWith('funcion-')) bloqueado = true;
  // Enlaces que abrirían otra app (YouTube, navegador).
  final w = e.widget;
  if (w is IconButton && (w.tooltip == 'Abrir' || w.tooltip == 'Referencia académica')) {
    bloqueado = true;
  }
  return bloqueado;
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Usuario torpe: $_acciones acciones al azar dentro de CEOSMOS sin fallos', (tester) async {
    // Sin audio real ni canales de plataforma: todo queda dentro de la app.
    final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final c in [
      'xyz.luan/audioplayers.global',
      'xyz.luan/audioplayers.global/events',
      'xyz.luan/audioplayers',
      'ceosmos/practicas',
      'plugins.flutter.io/url_launcher_android',
    ]) {
      m.setMockMethodCallHandler(MethodChannel(c), (_) async => null);
    }

    final api = FakeCeosmosApi()..addUser('torpe@example.com', 'Clave#2026', username: 'Torpe');
    final state = api.appState();
    addTearDown(state.dispose);
    Future<void> entrar() async =>
        state.acceptSession(await state.auth.login('torpe@example.com', 'Clave#2026'));
    await entrar();

    await tester.pumpWidget(CeosmosApp(state: state));
    await tester.pumpAndSettle();

    final azar = Random(_semilla);
    final errores = <String>[];
    var toques = 0, escrituras = 0, atras = 0, desplazamientos = 0, reingresos = 0;
    var fueraDeSesion = 0;
    final reloj = Stopwatch()..start();

    final tocables = find.byWidgetPredicate(
      (w) =>
          w is ButtonStyleButton ||
          w is IconButton ||
          w is InkWell ||
          w is ListTile ||
          w is ChoiceChip ||
          w is FilterChip ||
          w is Switch ||
          w is Slider ||
          w is NavigationDestination,
    ).hitTestable();

    for (var i = 0; i < _acciones; i++) {
      // Si el usuario cerró sesión o borró su cuenta, vuelve a entrar al rato.
      if (state.status == AuthStatus.signedOut) {
        if (++fueraDeSesion > 150) {
          if (api.users.values.every((u) => u.email != 'torpe@example.com')) {
            api.addUser('torpe@example.com', 'Clave#2026', username: 'Torpe');
          }
          await entrar();
          reingresos++;
          fueraDeSesion = 0;
        }
      }
      final tirada = azar.nextInt(100);
      try {
        if (tirada < 68) {
          final candidatos =
              tocables.evaluate().where((e) => !_bloqueado(e)).toList();
          if (candidatos.isNotEmpty) {
            final e = candidatos[azar.nextInt(candidatos.length)];
            await tester.tap(find.byElementPredicate((x) => x == e), warnIfMissed: false);
            toques++;
          }
        } else if (tirada < 83) {
          final campos = find.byType(EditableText).hitTestable().evaluate().toList();
          if (campos.isNotEmpty) {
            final e = campos[azar.nextInt(campos.length)];
            await tester.enterText(
              find.byElementPredicate((x) => x == e),
              _textos[azar.nextInt(_textos.length)],
            );
            if (azar.nextBool()) await tester.testTextInput.receiveAction(TextInputAction.done);
            escrituras++;
          }
        } else if (tirada < 93) {
          // «Atrás» dentro de la app: cierra diálogos, hojas y pantallas, nunca la app.
          final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
          await nav.maybePop();
          atras++;
        } else {
          final listas = find.byType(Scrollable).hitTestable().evaluate().toList();
          if (listas.isNotEmpty) {
            final e = listas[azar.nextInt(listas.length)];
            await tester.drag(
              find.byElementPredicate((x) => x == e),
              Offset(0, (azar.nextDouble() - .5) * 900),
              warnIfMissed: false,
            );
            desplazamientos++;
          }
        }
        await tester.pump(const Duration(milliseconds: 60));
      } catch (e) {
        errores.add('acción $i: $e');
      }
      final ex = tester.takeException();
      // En la PC no existen los plugins nativos (conectividad, BLE): no es un fallo de la app.
      if (ex != null && ex is! MissingPluginException) errores.add('acción $i: $ex');
      if (errores.length > 20) break;
    }
    reloj.stop();

    final resumen = 'MONO_RESUMEN acciones=$_acciones toques=$toques escrituras=$escrituras '
        'atras=$atras desplazamientos=$desplazamientos reingresos=$reingresos '
        'errores=${errores.length} segundos=${reloj.elapsed.inSeconds}';
    // ignore: avoid_print
    print(resumen);
    binding.reportData = {'resumen': resumen, 'errores': errores};
    expect(errores, isEmpty, reason: errores.take(5).join('\n'));
  }, timeout: const Timeout(Duration(minutes: 90)));
}

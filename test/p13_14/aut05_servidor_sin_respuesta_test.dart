// P13-14 · AUT-05 · Integración UI ↔ cliente HTTP real cuando el servidor NO responde.
// Prueba de widget sobre la pantalla de acceso real (AuthScreen + AppState + ApiClient):
//   a) conexión rechazada (puerto local cerrado) → «No hay conexión…»
//   b) el servidor acepta pero nunca contesta → tiempo límite → «…tardó demasiado…»
// En ambos casos la app no se cuelga: el botón vuelve a estar disponible y no hay sesión.
import 'dart:io';

import 'package:ceosmos_movil_integral/core/app_state.dart';
import 'package:ceosmos_movil_integral/data/api_client.dart';
import 'package:ceosmos_movil_integral/data/auth_repository.dart';
import 'package:ceosmos_movil_integral/data/ceosmos_repository.dart';
import 'package:ceosmos_movil_integral/data/token_store.dart';
import 'package:ceosmos_movil_integral/ui/auth_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/servidor_api_local.dart';

AppState _estado(String baseUrl, {Duration timeout = const Duration(seconds: 15)}) {
  final api = ApiClient(baseUrl: baseUrl, timeout: timeout);
  return AppState(
    auth: AuthRepository(api, MemoryTokenStore()),
    data: CeosmosRepository(api),
    startTicker: false,
  )..status = AuthStatus.signedOut;
}

Future<void> _intentarEntrar(WidgetTester tester) async {
  await tester.enterText(find.widgetWithText(TextFormField, 'Correo electrónico'), 'ana@ceosmos.mx');
  await tester.enterText(find.widgetWithText(TextFormField, 'Contraseña'), 'Orbita#2026');
  await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
  await tester.pump();
}

/// Deja avanzar la red real (fuera del reloj simulado) hasta que aparezca [texto].
Future<void> _esperarTexto(WidgetTester tester, String texto) async {
  for (var i = 0; i < 40 && find.text(texto).evaluate().isEmpty; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump();
  }
}

void main() {
  // TestWidgetsFlutterBinding responde 400 a todo HttpClient; aquí se necesita la red local real.
  setUp(() => HttpOverrides.global = null);

  testWidgets('Conexión rechazada → mensaje «No hay conexión…» y la app sigue usable', (tester) async {
    final puerto = (await tester.runAsync(puertoCerrado))!;
    final state = _estado('http://127.0.0.1:$puerto/api');
    addTearDown(state.dispose);
    await tester.pumpWidget(MaterialApp(home: AuthScreen(state: state)));

    await _intentarEntrar(tester);
    const mensaje = 'No hay conexión con el servidor de CEOSMOS. Revisa tu red.';
    await _esperarTexto(tester, mensaje);

    expect(find.text(mensaje), findsOneWidget);
    expect(state.status, AuthStatus.signedOut);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNotNull,
        reason: 'tras el error el botón vuelve a estar disponible (no se queda «cargando»)');
  });

  testWidgets('El servidor acepta pero no responde → tiempo límite y mensaje en pantalla', (tester) async {
    final servidor = (await tester.runAsync(ServidorApiLocal.iniciar))!..colgado = true;
    addTearDown(() => tester.runAsync(servidor.cerrar));
    final state = _estado(servidor.baseUrl, timeout: const Duration(seconds: 2));
    addTearDown(state.dispose);
    await tester.pumpWidget(MaterialApp(home: AuthScreen(state: state)));

    await _intentarEntrar(tester);
    // Deja que la petición salga por el socket real y llegue al servidor.
    for (var i = 0; i < 40 && servidor.peticiones.isEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 25)));
    }
    expect(servidor.peticiones.single.ruta, '/api/auth/login');
    expect(find.byType(CircularProgressIndicator), findsOneWidget, reason: 'mientras espera muestra progreso');

    await tester.pump(const Duration(seconds: 3)); // vence el plazo de 2 s del ApiClient
    await tester.pump();
    expect(find.text('El servidor de CEOSMOS tardó demasiado en responder. Intenta de nuevo.'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(state.status, AuthStatus.signedOut);
  });
}

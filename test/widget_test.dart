import 'package:ceosmos_movil_integral/app.dart';
import 'package:ceosmos_movil_integral/core/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_ceosmos_api.dart';

void mockAudio() {
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(const MethodChannel('xyz.luan/audioplayers.global'), (_) async => 1);
  messenger.setMockMethodCallHandler(const MethodChannel('xyz.luan/audioplayers.global/events'), (_) async => null);
  messenger.setMockMethodCallHandler(const MethodChannel('xyz.luan/audioplayers'), (call) async {
    if (call.method == 'create') {
      final id = (call.arguments as Map)['playerId'];
      messenger.setMockMethodCallHandler(MethodChannel('xyz.luan/audioplayers/events/$id'), (_) async => null);
    }
    return 1;
  });
}

Future<void> entrar(WidgetTester tester, String email, String password) async {
  await tester.enterText(find.widgetWithText(TextFormField, 'Correo electrónico'), email);
  await tester.enterText(find.widgetWithText(TextFormField, 'Contraseña'), password);
  await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(mockAudio);

  testWidgets('Acceso valida campos y ya no ofrece modo demo', (tester) async {
    final api = FakeCeosmosApi();
    final state = api.appState()..status = AuthStatus.signedOut;
    addTearDown(state.dispose);
    await tester.pumpWidget(CeosmosApp(state: state));
    await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
    await tester.pumpAndSettle();
    expect(find.text('Escribe tu correo.'), findsOneWidget);
    expect(find.text('Escribe tu contraseña.'), findsOneWidget);
    expect(find.text('Explorar demo'), findsNothing);
    expect(api.calls, isEmpty, reason: 'la validación ocurre antes de llamar al servidor');
  });

  testWidgets('Recorrido: entrar, favorito, sesión, pausa, terminar, historial y salir', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = FakeCeosmosApi();
    final user = api.addUser('ana@example.com', 'Clave#2026', username: 'Ana');
    final state = api.appState()..status = AuthStatus.signedOut;
    addTearDown(state.dispose);
    await tester.pumpWidget(CeosmosApp(state: state));
    await entrar(tester, 'ana@example.com', 'Clave#2026');
    expect(find.text('Hola, Ana ✦'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.explore_outlined).last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('Guardar Órbita tranquila'));
    await tester.tap(find.byTooltip('Guardar Órbita tranquila'));
    await tester.pumpAndSettle();
    expect(user.favorites, contains('orbit'));

    await tester.ensureVisible(find.text('Órbita tranquila'));
    await tester.tap(find.text('Órbita tranquila'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('5 min'));
    await tester.tap(find.text('Comenzar sesión'));
    await tester.pumpAndSettle();
    expect(find.text('05:00'), findsOneWidget);
    await tester.ensureVisible(find.text('Pausar sesión'));
    await tester.tap(find.text('Pausar sesión'));
    await tester.pumpAndSettle();
    expect(state.running, isFalse);
    await tester.tap(find.text('Continuar sesión'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Terminar sesión'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Terminar'));
    await tester.pumpAndSettle();
    expect(user.sessions, hasLength(1));

    await tester.tap(find.byIcon(Icons.person_outline_rounded).last);
    await tester.pumpAndSettle();
    expect(find.text('1 sesión'), findsOneWidget);
    await tester.ensureVisible(find.text('Cerrar sesión'));
    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Cerrar sesión'));
    await tester.pumpAndSettle();
    expect(find.text('Vuelve a tu centro.'), findsOneWidget);
    expect(api.calls, contains('POST /auth/logout'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('La sección de administración solo aparece para ADMIN', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = FakeCeosmosApi()
      ..addUser('user@example.com', 'Clave#2026', username: 'normal')
      ..addUser('admin@example.com', 'Clave#2026', username: 'jefa', role: 'ADMIN');
    final state = api.appState();
    addTearDown(state.dispose);
    await state.acceptSession(await state.auth.login('user@example.com', 'Clave#2026'));
    await tester.pumpWidget(CeosmosApp(state: state));
    await tester.tap(find.byIcon(Icons.person_outline_rounded).last);
    await tester.pumpAndSettle();
    expect(find.text('Administración'), findsNothing);
    await state.signOut();
    await state.acceptSession(await state.auth.login('admin@example.com', 'Clave#2026'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.person_outline_rounded).last);
    await tester.pumpAndSettle();
    expect(find.text('Administración'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  for (final width in [280.0, 320.0, 768.0, 1440.0]) {
    testWidgets('Navegación y dispositivos sin desbordes a $width px', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = FakeCeosmosApi()..addUser('a@example.com', 'Clave#2026', username: 'Ana');
      final state = api.appState();
      addTearDown(state.dispose);
      await state.acceptSession(await state.auth.login('a@example.com', 'Clave#2026'));
      await tester.pumpWidget(CeosmosApp(state: state));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.devices_other_outlined).last);
      await tester.pumpAndSettle();
      expect(find.text('Sin dispositivos vinculados'), findsOneWidget);
      expect(find.textContaining('FICTICIOS'), findsNothing);
      await tester.tap(find.byIcon(Icons.support_agent_outlined).last);
      await tester.pumpAndSettle();
      expect(find.text('Tickets y chat interno'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
  }
}

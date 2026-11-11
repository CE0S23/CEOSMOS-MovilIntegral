import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ceosmos_movil_integral/app.dart';
import 'package:ceosmos_movil_integral/core/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      (_) async => 1,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global/events'),
      (_) async => null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (call) async {
        if (call.method == 'create') {
          final id = (call.arguments as Map)['playerId'];
          messenger.setMockMethodCallHandler(
            MethodChannel('xyz.luan/audioplayers/events/$id'),
            (_) async => null,
          );
        }
        return 1;
      },
    );
  });

  testWidgets('Login validates fields and explains passkeys honestly', (
    tester,
  ) async {
    final state = AppState(startTicker: false);
    addTearDown(state.dispose);
    await tester.pumpWidget(CeosmosApp(state: state));
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();
    expect(find.text('Escribe un correo válido.'), findsOneWidget);
    expect(find.text('Usa al menos 8 caracteres.'), findsOneWidget);
    await tester.ensureVisible(find.text('Acerca del acceso con passkey'));
    await tester.tap(find.text('Acerca del acceso con passkey'));
    await tester.pumpAndSettle();
    expect(find.text('Passkeys en la siguiente integración'), findsOneWidget);
  });

  testWidgets(
    'Mobile demo: favorite, filter, session, pause, finish, history, logout',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final state = AppState(startTicker: false);
      addTearDown(state.dispose);
      await tester.pumpWidget(CeosmosApp(state: state));
      await tester.ensureVisible(find.text('Explorar demo'));
      await tester.tap(find.text('Explorar demo'));
      await tester.pumpAndSettle();
      expect(find.text('Hola, Explorador ✦'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byIcon(Icons.explore_outlined).last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byTooltip('Guardar Órbita tranquila'));
      await tester.tap(find.byTooltip('Guardar Órbita tranquila'));
      await tester.pumpAndSettle();
      expect(state.workspace.favorites, contains('orbit'));
      await tester.ensureVisible(find.text('Mis favoritos'));
      await tester.tap(find.text('Mis favoritos'));
      await tester.pumpAndSettle();
      expect(find.text('Bosque en calma'), findsNothing);
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
      expect(state.running, isTrue);
      await tester.tap(find.text('Terminar sesión'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Terminar'));
      await tester.pumpAndSettle();
      expect(state.workspace.history, hasLength(1));
      await tester.tap(find.byIcon(Icons.person_outline_rounded).last);
      await tester.pumpAndSettle();
      expect(find.text('1 sesiones'), findsOneWidget);
      await tester.ensureVisible(find.text('Cerrar sesión'));
      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Cerrar sesión'));
      await tester.pumpAndSettle();
      expect(find.text('Vuelve a tu centro.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final width in [320.0, 768.0, 1440.0]) {
    testWidgets('Navigation and simulated devices fit width $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final state = AppState(startTicker: false);
      addTearDown(state.dispose);
      state.acceptSession(await state.auth.enterDemo());
      await tester.pumpWidget(CeosmosApp(state: state));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byIcon(Icons.devices_other_outlined).last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Simular vinculación').first);
      await tester.tap(find.text('Simular vinculación').first);
      await tester.pumpAndSettle();
      expect(state.workspace.devices, hasLength(1));
      expect(find.text('DATOS FICTICIOS'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
  }
}

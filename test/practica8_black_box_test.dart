// PRÁCTICA 8. Pruebas de caja negra: entradas por controles y salidas visibles.
// Ejecutar con: flutter test test/practica8_black_box_test.dart
import 'dart:async';

import 'package:ceosmos_movil_integral/app.dart';
import 'package:ceosmos_movil_integral/core/app_state.dart';
import 'package:ceosmos_movil_integral/data/auth_repository.dart';
import 'package:ceosmos_movil_integral/data/catalog.dart';
import 'package:audioplayers_platform_interface/audioplayers_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Reinicia el ámbito global del plugin entre zonas fakeAsync de testWidgets.
    GlobalAudioplayersPlatformInterface.instance = _FakeGlobalAudioPlatform();
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
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

  Future<AppState> launch(WidgetTester tester, {AppState? state}) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final appState = state ?? AppState(startTicker: false);
    addTearDown(appState.dispose);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
    await tester.pumpWidget(CeosmosApp(state: appState));
    await tester.pumpAndSettle();
    return appState;
  }

  Future<void> tapText(WidgetTester tester, String label) async {
    final target = find.text(label).last;
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  Future<void> register(
    WidgetTester tester,
    String name,
    String email,
    String password,
  ) async {
    await tapText(tester, '¿Primera vez? Crea una cuenta');
    await tester.enterText(find.widgetWithText(TextFormField, 'Nombre'), name);
    await tester.enterText(find.widgetWithText(TextFormField, 'Correo electrónico'), email);
    await tester.enterText(find.widgetWithText(TextFormField, 'Contraseña'), password);
    await tapText(tester, 'Crear cuenta local');
  }

  Future<void> login(WidgetTester tester, String email, String password) async {
    await tester.enterText(find.widgetWithText(TextFormField, 'Correo electrónico'), email);
    await tester.enterText(find.widgetWithText(TextFormField, 'Contraseña'), password);
    await tapText(tester, 'Iniciar sesión');
  }

  Future<void> demo(WidgetTester tester) async {
    await tapText(tester, 'Explorar demo');
    expect(find.text('Hola, Explorador ✦'), findsOneWidget);
  }

  Future<void> tab(WidgetTester tester, IconData icon) async {
    await tester.tap(find.byIcon(icon).last);
    await tester.pumpAndSettle();
  }

  Future<void> signOut(WidgetTester tester) async {
    await tab(tester, Icons.person_outline_rounded);
    await tapText(tester, 'Cerrar sesión');
    await tester.tap(find.widgetWithText(FilledButton, 'Cerrar sesión'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    expect(find.text('Vuelve a tu centro.'), findsOneWidget);
  }

  Future<void> startOrbit(WidgetTester tester) async {
    await tab(tester, Icons.explore_outlined);
    await tapText(tester, 'Órbita tranquila');
    await tapText(tester, '5 min');
    await tapText(tester, 'Comenzar sesión');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    expect(find.text('Objetivo: 5 minutos'), findsOneWidget);
  }

  testWidgets('CP-01 REQ-VAL-01 nombre de un carácter se rechaza', (tester) async {
    await launch(tester);
    await register(tester, 'A', 'a@ceosmos.mx', 'clave1234');
    expect(find.text('Escribe al menos 2 caracteres.'), findsOneWidget);
    expect(find.text('Un nuevo comienzo.'), findsOneWidget);
  });

  testWidgets('CP-02 REQ-VAL-01 contraseña de siete caracteres se rechaza', (tester) async {
    await launch(tester);
    await register(tester, 'Ana', 'ana@ceosmos.mx', 'clave12');
    expect(find.text('Usa al menos 8 caracteres.'), findsOneWidget);
    expect(find.text('Un nuevo comienzo.'), findsOneWidget);
  });

  testWidgets('CP-03 REQ-VAL-01 correo sin arroba se rechaza', (tester) async {
    await launch(tester);
    await register(tester, 'Ana', 'correo-invalido', 'clave1234');
    expect(find.text('Escribe un correo válido.'), findsOneWidget);
  });

  testWidgets('CP-04 REQ-VAL-01 registro válido normaliza el correo', (tester) async {
    await launch(tester);
    await register(tester, 'Ana', ' ANA@CEOSMOS.MX ', 'clave1234');
    expect(find.text('Hola, Ana ✦'), findsOneWidget);
    await tab(tester, Icons.person_outline_rounded);
    expect(find.text('ana@ceosmos.mx'), findsOneWidget);
  });

  testWidgets('CP-05 REQ-VAL-02 correo duplicado se rechaza', (tester) async {
    await launch(tester);
    await register(tester, 'Ana', 'ana@ceosmos.mx', 'clave1234');
    await signOut(tester);
    await register(tester, 'Otra', 'ANA@CEOSMOS.MX', 'clave9999');
    expect(find.text('Este correo ya tiene una cuenta local. Inicia sesión.'), findsOneWidget);
    expect(find.text('Un nuevo comienzo.'), findsOneWidget);
  });

  testWidgets('CP-06 REQ-VAL-02 contraseña incorrecta no concede acceso', (tester) async {
    await launch(tester);
    await register(tester, 'Ana', 'ana@ceosmos.mx', 'clave1234');
    await signOut(tester);
    await login(tester, 'ana@ceosmos.mx', 'erronea9');
    expect(find.text('Correo o contraseña incorrectos. Crea una cuenta local o entra a la demo.'), findsOneWidget);
    expect(find.text('Vuelve a tu centro.'), findsOneWidget);
  });

  testWidgets('CP-07 REQ-OP-02 búsqueda normaliza acentos y muestra vacío', (tester) async {
    await launch(tester);
    await demo(tester);
    await tab(tester, Icons.explore_outlined);
    final search = find.byType(TextField);
    await tester.enterText(search, 'ORBITA');
    await tester.pumpAndSettle();
    expect(find.text('1 experiencias · Disponibles sin conexión'), findsOneWidget);
    expect(find.text('Órbita tranquila'), findsOneWidget);
    await tester.enterText(search, 'inexistente_123');
    await tester.pumpAndSettle();
    expect(find.text('0 experiencias · Disponibles sin conexión'), findsOneWidget);
    expect(find.text('No encontramos esa experiencia'), findsOneWidget);
  });

  testWidgets('CP-08 REQ-OP-02 filtros de modo y tipo se combinan', (tester) async {
    await launch(tester);
    await demo(tester);
    await tab(tester, Icons.explore_outlined);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Relajación'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, 'Audio'));
    await tester.pumpAndSettle();
    expect(find.text('1 experiencias · Disponibles sin conexión'), findsOneWidget);
    expect(find.text('Bosque en calma'), findsOneWidget);
    expect(find.text('Respira con el océano'), findsNothing);
  });

  testWidgets('CP-09 REQ-OP-03 favoritos se agregan y eliminan', (tester) async {
    await launch(tester);
    await demo(tester);
    await tab(tester, Icons.explore_outlined);
    await tester.ensureVisible(find.byTooltip('Guardar Órbita tranquila'));
    await tester.tap(find.byTooltip('Guardar Órbita tranquila'));
    await tester.pumpAndSettle();
    await tapText(tester, 'Mis favoritos');
    expect(find.text('1 experiencias · Disponibles sin conexión'), findsOneWidget);
    await tester.tap(find.byTooltip('Quitar Órbita tranquila de favoritos'));
    await tester.pumpAndSettle();
    expect(find.text('Tu colección está por comenzar'), findsOneWidget);
    await tab(tester, Icons.person_outline_rounded);
    expect(find.text('0 experiencias guardadas'), findsOneWidget);
  });

  testWidgets('CP-10 REQ-OP-01 sesión pausa, continúa y termina una vez', (tester) async {
    var clock = DateTime(2026, 10, 23, 12);
    final state = AppState(
      auth: MemoryAuthRepository(now: () => clock),
      now: () => clock,
      startTicker: false,
    );
    await launch(tester, state: state);
    await demo(tester);
    await startOrbit(tester);
    expect(find.text('05:00'), findsOneWidget);
    clock = clock.add(const Duration(seconds: 40));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('04:20'), findsOneWidget);
    await tapText(tester, 'Pausar sesión');
    expect(find.text('A TU RITMO · EN PAUSA'), findsOneWidget);
    clock = clock.add(const Duration(minutes: 10));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('04:20'), findsOneWidget);
    await tapText(tester, 'Continuar sesión');
    expect(find.text('RESPIRA. ESTÁS AQUÍ.'), findsOneWidget);
    await tapText(tester, 'Terminar sesión');
    await tapText(tester, 'Terminar');
    expect(find.text('Todo empieza con una pausa'), findsOneWidget);
    await tab(tester, Icons.person_outline_rounded);
    expect(find.text('1 sesiones'), findsOneWidget);
    expect(find.text('Finalizada'), findsOneWidget);
  });

  testWidgets('CP-11 REQ-OP-04 Band y TV se vinculan y desvinculan', (tester) async {
    await launch(tester);
    await demo(tester);
    await tab(tester, Icons.devices_other_outlined);
    await tester.ensureVisible(find.text('Simular vinculación').first);
    await tester.tap(find.text('Simular vinculación').first);
    await tester.pumpAndSettle();
    expect(find.text('DATOS FICTICIOS'), findsOneWidget);
    await tester.ensureVisible(find.text('Simular vinculación').first);
    await tester.tap(find.text('Simular vinculación').first);
    await tester.pumpAndSettle();
    expect(find.text('TV simulada · Esperando sesión'), findsOneWidget);
    expect(find.text('Demo activa'), findsNWidgets(2));
    await tester.ensureVisible(find.text('Desvincular demo').first);
    await tester.tap(find.text('Desvincular demo').first);
    await tester.pumpAndSettle();
    expect(find.text('DATOS FICTICIOS'), findsNothing);
    expect(find.text('Demo activa'), findsOneWidget);
  });

  testWidgets('CP-12 REQ-DAT-01 espacios de dos cuentas permanecen aislados', (tester) async {
    await launch(tester);
    await register(tester, 'Ana', 'ana@ceosmos.mx', 'clave1234');
    await tab(tester, Icons.explore_outlined);
    await tester.ensureVisible(find.byTooltip('Guardar Órbita tranquila'));
    await tester.tap(find.byTooltip('Guardar Órbita tranquila'));
    await tester.pumpAndSettle();
    await signOut(tester);
    await register(tester, 'Beto', 'beto@ceosmos.mx', 'clave5678');
    await tab(tester, Icons.person_outline_rounded);
    expect(find.text('0 experiencias guardadas'), findsOneWidget);
    expect(find.text('0 sesiones'), findsOneWidget);
    await signOut(tester);
    await login(tester, 'ana@ceosmos.mx', 'clave1234');
    await tab(tester, Icons.person_outline_rounded);
    expect(find.text('1 experiencias guardadas'), findsOneWidget);
  });

  testWidgets('CP-13 REQ-DAT-02 historial conserva una finalización', (tester) async {
    await launch(tester);
    await demo(tester);
    await startOrbit(tester);
    await tapText(tester, 'Terminar sesión');
    await tapText(tester, 'Terminar');
    await tab(tester, Icons.person_outline_rounded);
    expect(find.text('1 sesiones'), findsOneWidget);
    expect(find.text('Órbita tranquila'), findsOneWidget);
    await tab(tester, Icons.timelapse_rounded);
    await tab(tester, Icons.person_outline_rounded);
    expect(find.text('1 sesiones'), findsOneWidget);
  });

  testWidgets('CP-14 REQ-NAV-01 acceso privado se revoca al vencer', (tester) async {
    var clock = DateTime(2026, 10, 23, 12);
    final state = AppState(
      auth: MemoryAuthRepository(now: () => clock),
      now: () => clock,
      startTicker: false,
    );
    await launch(tester, state: state);
    await demo(tester);
    clock = clock.add(const Duration(hours: 2));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('Vuelve a tu centro.'), findsOneWidget);
    expect(find.text('Tu sesión local expiró. Vuelve a entrar.'), findsOneWidget);
    expect(find.text('Explora tu cosmos'), findsNothing);
  });

  for (final width in [320.0, 390.0, 768.0, 1440.0]) {
    testWidgets('CP-15-${width.toInt()} REQ-NAV-02 navegación sin overflow a ${width.toInt()} px', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final state = AppState(startTicker: false);
      addTearDown(state.dispose);
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      });
      await tester.pumpWidget(CeosmosApp(state: state));
      await demo(tester);
      expect(find.byType(NavigationBar), width < 920 ? findsOneWidget : findsNothing);
      expect(find.byType(ListTile), width >= 920 ? findsAtLeastNWidgets(5) : findsNothing);
      await tab(tester, Icons.devices_other_outlined);
      expect(find.text('Tu ecosistema'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('CP-16 REQ-ERR-01 fallo de audio muestra aviso y conserva sesión', (tester) async {
    await launch(tester);
    await demo(tester);
    await startOrbit(tester);
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (call) async {
        if (call.method == 'setReleaseMode') {
          throw PlatformException(code: 'audio_failure');
        }
        return 1;
      },
    );
    await tester.ensureVisible(find.byTooltip('Reproducir ambiente'));
    await tester.tap(find.byTooltip('Reproducir ambiente'));
    await tester.pumpAndSettle();
    expect(find.text('No se pudo reproducir el audio. Puedes reintentarlo o continuar en silencio.'), findsOneWidget);
    expect(find.text('Objetivo: 5 minutos'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('CP-17 REQ-VAL-03 duración inválida se rechaza sin cambiar preferencia', (tester) async {
    final state = await launch(tester);
    await demo(tester);
    await tab(tester, Icons.person_outline_rounded);
    await tapText(tester, '45 min');
    expect(tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '45 min')).selected, isTrue);
    expect(() => state.setPreferredMinutes(10), throwsArgumentError);
    await tester.pumpAndSettle();
    expect(tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '45 min')).selected, isTrue);
    expect(() => state.startSession(catalog.first, 0), throwsArgumentError);
    await tab(tester, Icons.timelapse_rounded);
    expect(find.text('Todo empieza con una pausa'), findsOneWidget);
  });

  testWidgets('CP-18 REQ-DAT-02 sesión completa guarda 05:00 una sola vez', (tester) async {
    var clock = DateTime(2026, 10, 23, 12);
    final state = AppState(
      auth: MemoryAuthRepository(now: () => clock),
      now: () => clock,
      startTicker: false,
    );
    await launch(tester, state: state);
    await demo(tester);
    await startOrbit(tester);
    clock = clock.add(const Duration(minutes: 5));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    await tab(tester, Icons.person_outline_rounded);
    expect(find.text('1 sesiones'), findsOneWidget);
    expect(find.text('Completada'), findsOneWidget);
    expect(find.text('05:00'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('1 sesiones'), findsOneWidget);
  });
}

class _FakeGlobalAudioPlatform implements GlobalAudioplayersPlatformInterface {
  @override
  Future<void> init() async {}

  @override
  Future<void> setGlobalAudioContext(AudioContext context) async {}

  @override
  Future<void> emitGlobalLog(String message) async {}

  @override
  Future<void> emitGlobalError(String code, String message) async {}

  @override
  Stream<GlobalAudioEvent> getGlobalEventStream() => const Stream.empty();
}

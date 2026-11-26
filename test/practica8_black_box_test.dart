// PRÁCTICA 8. Pruebas de caja negra: entradas por controles y salidas visibles.
// Ejecutar con: flutter test test/practica8_black_box_test.dart
// Desde la Fase 4 la app usa la API real; aquí se ejecuta contra un doble HTTP
// del contrato de la API (test/support/fake_ceosmos_api.dart).
import 'dart:async';

import 'package:ceosmos_movil_integral/app.dart';
import 'package:ceosmos_movil_integral/core/app_state.dart';
import 'package:ceosmos_movil_integral/data/catalog.dart';
import 'package:audioplayers_platform_interface/audioplayers_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_ceosmos_api.dart';

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

  late FakeCeosmosApi api;
  setUp(() {
    api = FakeCeosmosApi()..addUser('demo@ceosmos.mx', 'Clave#2026', username: 'Explorador');
  });

  Future<AppState> launch(WidgetTester tester, {AppState? state}) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final appState = state ?? api.appState();
    if (appState.status == AuthStatus.restoring) appState.status = AuthStatus.signedOut;
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
    await tester.enterText(find.widgetWithText(TextFormField, 'Nombre de usuario'), name);
    await tester.enterText(find.widgetWithText(TextFormField, 'Correo electrónico'), email);
    await tester.enterText(find.widgetWithText(TextFormField, 'Contraseña nueva'), password);
    await tester.tap(find.widgetWithText(FilledButton, 'Crear cuenta'));
    await tester.pumpAndSettle();
  }

  Future<void> login(WidgetTester tester, String email, String password) async {
    await tester.enterText(find.widgetWithText(TextFormField, 'Correo electrónico'), email);
    await tester.enterText(find.widgetWithText(TextFormField, 'Contraseña'), password);
    await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
    await tester.pumpAndSettle();
  }

  /// Verifica el correo con el código que el servidor envió.
  Future<void> verify(WidgetTester tester, String email) async {
    await tester.enterText(find.widgetWithText(TextFormField, 'Código de verificación'), api.verificationCodes[email]!);
    await tester.tap(find.widgetWithText(FilledButton, 'Verificar'));
    await tester.pumpAndSettle();
  }

  /// Entra con la cuenta de prueba registrada en el servidor.
  Future<void> demo(WidgetTester tester) async {
    await login(tester, 'demo@ceosmos.mx', 'Clave#2026');
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

  testWidgets('CP-01 REQ-VAL-01 nombre de dos caracteres se rechaza', (tester) async {
    await launch(tester);
    await register(tester, 'An', 'a@ceosmos.mx', 'Clave#2026');
    expect(find.text('Entre 3 y 30 caracteres.'), findsOneWidget);
    expect(api.calls, isEmpty);
  });

  testWidgets('CP-02 REQ-VAL-01 contraseña sin la política del servidor se rechaza', (tester) async {
    await launch(tester);
    await register(tester, 'Ana', 'ana@ceosmos.mx', 'clave1234');
    expect(find.text('Usa mayúscula, minúscula, número y símbolo.'), findsOneWidget);
    expect(api.calls, isEmpty);
  });

  testWidgets('CP-03 REQ-VAL-01 correo sin arroba se rechaza', (tester) async {
    await launch(tester);
    await register(tester, 'Ana', 'correo-invalido', 'Clave#2026');
    expect(find.text('Escribe un correo válido.'), findsOneWidget);
  });

  testWidgets('CP-04 REQ-VAL-01 registro válido normaliza el correo y pide verificación', (tester) async {
    await launch(tester);
    await register(tester, 'Ana', ' ANA@CEOSMOS.MX ', 'Clave#2026');
    expect(find.text('Verifica tu correo.'), findsOneWidget);
    await verify(tester, 'ana@ceosmos.mx');
    expect(find.text('Correo verificado. Ya puedes iniciar sesión.'), findsOneWidget);
    await login(tester, 'ana@ceosmos.mx', 'Clave#2026');
    expect(find.text('Hola, Ana ✦'), findsOneWidget);
  });

  testWidgets('CP-05 REQ-VAL-02 correo duplicado se rechaza', (tester) async {
    await launch(tester);
    await register(tester, 'Otra', 'DEMO@CEOSMOS.MX', 'Clave#2026');
    expect(find.text('Ese correo o nombre de usuario ya está registrado.'), findsOneWidget);
  });

  testWidgets('CP-06 REQ-VAL-02 contraseña incorrecta no concede acceso', (tester) async {
    await launch(tester);
    await login(tester, 'demo@ceosmos.mx', 'Erronea#99');
    expect(find.text('Correo o contraseña incorrectos.'), findsOneWidget);
    expect(find.text('Explora tu cosmos'), findsNothing);
  });

  testWidgets('CP-07 REQ-OP-02 búsqueda normaliza acentos y muestra vacío', (tester) async {
    await launch(tester);
    await demo(tester);
    await tab(tester, Icons.explore_outlined);
    final search = find.byType(TextField);
    await tester.enterText(search, 'ORBITA');
    await tester.pumpAndSettle();
    expect(find.text('1 experiencia · Disponibles sin conexión'), findsOneWidget);
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
    expect(find.text('1 experiencia · Disponibles sin conexión'), findsOneWidget);
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
    expect(find.text('1 experiencia · Disponibles sin conexión'), findsOneWidget);
    await tester.tap(find.byTooltip('Quitar Órbita tranquila de favoritos'));
    await tester.pumpAndSettle();
    expect(find.text('Tu colección está por comenzar'), findsOneWidget);
    await tab(tester, Icons.person_outline_rounded);
    expect(find.text('0 experiencias guardadas'), findsOneWidget);
  });

  testWidgets('CP-10 REQ-OP-01 sesión pausa, continúa y termina una vez', (tester) async {
    var clock = DateTime(2026, 10, 23, 12);
    final state = api.appState(now: () => clock);
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
    expect(find.text('1 sesión'), findsOneWidget);
    expect(find.text('Finalizada'), findsOneWidget);
  });

  testWidgets('CP-11 REQ-OP-04 wearable se vincula y desvincula en la cuenta', (tester) async {
    await launch(tester);
    await demo(tester);
    await tab(tester, Icons.devices_other_outlined);
    expect(find.text('Sin dispositivos vinculados'), findsOneWidget);
    await tapText(tester, 'Vincular wearable');
    await tester.enterText(find.widgetWithText(TextFormField, 'Dirección TCP (IP:puerto)'), 'sin-puerto');
    await tester.tap(find.widgetWithText(FilledButton, 'Vincular'));
    await tester.pumpAndSettle();
    expect(find.text('Usa el formato IP:puerto.'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextFormField, 'Dirección TCP (IP:puerto)'), '192.168.1.40:5050');
    await tester.tap(find.widgetWithText(FilledButton, 'Vincular'));
    await tester.pumpAndSettle();
    expect(find.text('TCP · 192.168.1.40:5050'), findsOneWidget);
    expect(api.users.values.first.devices, hasLength(1));
    await tester.tap(find.byTooltip('Desvincular'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Desvincular'));
    await tester.pumpAndSettle();
    expect(find.text('Sin dispositivos vinculados'), findsOneWidget);
    expect(api.users.values.first.devices, isEmpty);
    expect(find.textContaining('FICTICIOS'), findsNothing);
  });

  testWidgets('CP-12 REQ-DAT-01 espacios de dos cuentas permanecen aislados', (tester) async {
    await launch(tester);
    api.addUser('ana@ceosmos.mx', 'Clave#2026', username: 'Ana');
    api.addUser('beto@ceosmos.mx', 'Clave#5678', username: 'Beto');
    await login(tester, 'ana@ceosmos.mx', 'Clave#2026');
    await tab(tester, Icons.explore_outlined);
    await tester.ensureVisible(find.byTooltip('Guardar Órbita tranquila'));
    await tester.tap(find.byTooltip('Guardar Órbita tranquila'));
    await tester.pumpAndSettle();
    await signOut(tester);
    await login(tester, 'beto@ceosmos.mx', 'Clave#5678');
    await tab(tester, Icons.person_outline_rounded);
    expect(find.text('0 experiencias guardadas'), findsOneWidget);
    expect(find.text('0 sesiones'), findsOneWidget);
    await signOut(tester);
    await login(tester, 'ana@ceosmos.mx', 'Clave#2026');
    await tab(tester, Icons.person_outline_rounded);
    expect(find.text('1 experiencia guardada'), findsOneWidget);
  });

  testWidgets('CP-13 REQ-DAT-02 historial conserva una finalización', (tester) async {
    await launch(tester);
    await demo(tester);
    await startOrbit(tester);
    await tapText(tester, 'Terminar sesión');
    await tapText(tester, 'Terminar');
    await tab(tester, Icons.person_outline_rounded);
    expect(find.text('1 sesión'), findsOneWidget);
    expect(find.text('Órbita tranquila'), findsOneWidget);
    await tab(tester, Icons.timelapse_rounded);
    await tab(tester, Icons.person_outline_rounded);
    expect(find.text('1 sesión'), findsOneWidget);
  });

  testWidgets('CP-14 REQ-NAV-01 acceso privado se revoca cuando el servidor invalida la sesión', (tester) async {
    final state = await launch(tester);
    await demo(tester);
    api.revokeAll();
    await state.loadWorkspace();
    await tester.pumpAndSettle();
    expect(find.text('Vuelve a tu centro.'), findsOneWidget);
    expect(find.textContaining('Tu sesión expiró'), findsOneWidget);
    expect(find.text('Explora tu cosmos'), findsNothing);
  });

  for (final width in [320.0, 390.0, 768.0, 1440.0]) {
    testWidgets('CP-15-${width.toInt()} REQ-NAV-02 navegación sin overflow a ${width.toInt()} px', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final state = api.appState()..status = AuthStatus.signedOut;
      addTearDown(state.dispose);
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      });
      await tester.pumpWidget(CeosmosApp(state: state));
      await demo(tester);
      expect(find.byType(NavigationBar), width < 920 ? findsOneWidget : findsNothing);
      expect(find.byType(ListTile), width >= 920 ? findsAtLeastNWidgets(6) : findsNothing);
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
    final state = api.appState(now: () => clock);
    await launch(tester, state: state);
    await demo(tester);
    await startOrbit(tester);
    clock = clock.add(const Duration(minutes: 5));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    await tab(tester, Icons.person_outline_rounded);
    expect(find.text('1 sesión'), findsOneWidget);
    expect(find.text('Completada'), findsOneWidget);
    expect(find.text('05:00'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('1 sesión'), findsOneWidget);
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

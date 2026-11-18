// Práctica 12 · Fase 2: profiling de la app en el dispositivo (modo profile).
//
//   flutter drive --profile -d <id> --driver=test_driver/p12_perfil_driver.dart \
//     --target=integration_test/p12_perfil_app_test.dart \
//     --dart-define=CEOSMOS_API_URL=http://10.0.2.2:8080/api \
//     --dart-define=E2E_EMAIL=... --dart-define=E2E_PASSWORD=...
//
// Ejecuta las 6 pruebas obligatorias y guarda el inicio/fin (epoch ms) de cada fase
// para cruzarlas con el CPU y la memoria que muestrea el equipo con adb
// (p11yp12/p12/scripts/fase2_muestrear_app.js). Los resultados van en reportData.
import 'dart:async';
import 'dart:convert';

import 'package:ceosmos_movil_integral/app.dart';
import 'package:ceosmos_movil_integral/core/app_state.dart';
import 'package:ceosmos_movil_integral/core/config.dart';
import 'package:ceosmos_movil_integral/data/api_client.dart';
import 'package:ceosmos_movil_integral/data/auth_repository.dart';
import 'package:ceosmos_movil_integral/data/catalog.dart';
import 'package:ceosmos_movil_integral/data/ceosmos_repository.dart';
import 'package:ceosmos_movil_integral/data/token_store.dart';
import 'package:ceosmos_movil_integral/domain/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';

const _email = String.fromEnvironment('E2E_EMAIL');
const _password = String.fromEnvironment('E2E_PASSWORD');

Map<String, num> _stats(List<num> v) {
  if (v.isEmpty) return {'n': 0};
  final s = [...v]..sort();
  num p(double q) => s[((q / 100) * (s.length - 1)).round()];
  return {
    'n': s.length,
    'prom': s.reduce((a, b) => a + b) / s.length,
    'p50': p(50), 'p90': p(90), 'p95': p(95), 'max': s.last, 'min': s.first,
  };
}

/// Detecta bloqueos del hilo principal: un Timer de 8 ms que mide su propio retraso.
class _SondaBloqueo {
  final _retrasos = <double>[];
  Timer? _t;
  final _sw = Stopwatch();
  void iniciar() {
    _retrasos.clear();
    _sw..reset()..start();
    var ultimo = 0;
    _t = Timer.periodic(const Duration(milliseconds: 8), (_) {
      final ahora = _sw.elapsedMicroseconds;
      _retrasos.add((ahora - ultimo) / 1000 - 8);
      ultimo = ahora;
    });
  }

  Map<String, Object> detener() {
    _t?.cancel();
    return {
      'max_retraso_ms': _retrasos.isEmpty ? 0 : _retrasos.reduce((a, b) => a > b ? a : b),
      'bloqueos_sobre_16ms': _retrasos.where((r) => r > 16.7).length,
      'bloqueos_sobre_50ms': _retrasos.where((r) => r > 50).length,
    };
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('P12 profiling: consulta, escritura, navegación, procesamiento y reposo', (tester) async {
    final fases = <Map<String, Object>>[];
    final datos = <String, Object>{};
    final sonda = _SondaBloqueo();
    Future<T> fase<T>(String nombre, Future<T> Function() fn) async {
      final ini = DateTime.now().millisecondsSinceEpoch;
      sonda.iniciar();
      final r = await fn();
      fases.add({'fase': nombre, 'inicio': ini, 'fin': DateTime.now().millisecondsSinceEpoch, ...sonda.detener()});
      return r;
    }

    final api = ApiClient(baseUrl: AppConfig.apiBaseUrl);
    final state = AppState(auth: AuthRepository(api, MemoryTokenStore()), data: CeosmosRepository(api));
    await Future<void>.delayed(const Duration(seconds: 3)); // línea base de CPU/RAM

    // 0. Inicio de sesión + carga inicial (operación crítica de arranque)
    await fase('carga_inicial', () async {
      final sw = Stopwatch()..start();
      await state.acceptSession(await state.auth.login(_email, _password));
      datos['carga_inicial_ms'] = sw.elapsedMilliseconds;
      datos['sesiones_cargadas'] = state.workspace.history.length;
    });

    // 1. Consulta repetida: recarga completa de datos ×20 e historial ×30
    await fase('consulta_repetida', () async {
      final recarga = <num>[], historial = <num>[];
      for (var i = 0; i < 20; i++) {
        final sw = Stopwatch()..start();
        await state.loadWorkspace();
        recarga.add(sw.elapsedMicroseconds / 1000);
      }
      for (var i = 0; i < 30; i++) {
        final sw = Stopwatch()..start();
        await state.data.focusSessions();
        historial.add(sw.elapsedMicroseconds / 1000);
      }
      datos['recarga_workspace_ms'] = _stats(recarga);
      datos['consulta_historial_ms'] = _stats(historial);
    });

    // 2. Escritura: 10 sesiones de enfoque guardadas en el servidor
    await fase('escritura', () async {
      final t = <num>[];
      final media = catalog.first;
      for (var i = 0; i < 10; i++) {
        state.startSession(media, 5);
        final sw = Stopwatch()..start();
        await state.finishSession();
        t.add(sw.elapsedMicroseconds / 1000);
      }
      datos['guardar_sesion_ms'] = _stats(t);
      datos['pendientes_tras_escritura'] = state.pendingSessions;
    });

    // 3. Navegación entre pantallas principales con desplazamiento (FrameTiming)
    await tester.pumpWidget(CeosmosApp(state: state));
    await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 20));
    final cuadros = <FrameTiming>[];
    void alRecibir(List<FrameTiming> t) => cuadros.addAll(t);
    SchedulerBinding.instance.addTimingsCallback(alRecibir);
    await fase('navegacion', () async {
      for (var vuelta = 0; vuelta < 2; vuelta++) {
        for (final icono in [
          Icons.explore_outlined, Icons.timelapse_rounded, Icons.devices_other_outlined,
          Icons.person_outline_rounded, Icons.grid_view_rounded,
        ]) {
          await tester.tap(find.byIcon(icono).last);
          await tester.pumpAndSettle();
          final s = find.byType(Scrollable).first;
          for (var i = 0; i < 3; i++) {
            await tester.fling(s, const Offset(0, -700), 2500);
            await tester.pumpAndSettle();
          }
          await tester.fling(s, const Offset(0, 2400), 3000);
          await tester.pumpAndSettle();
        }
      }
    });
    await tester.pump(const Duration(milliseconds: 500));
    SchedulerBinding.instance.removeTimingsCallback(alRecibir);
    double ms(Duration d) => d.inMicroseconds / 1000;
    final build = cuadros.map((c) => ms(c.buildDuration)).toList();
    final raster = cuadros.map((c) => ms(c.rasterDuration)).toList();
    datos['navegacion_cuadros'] = {
      'cuadros': cuadros.length,
      'build_ms': _stats(build), 'raster_ms': _stats(raster),
      'build_sobre_16_7ms': build.where((x) => x > 16.7).length,
      'raster_sobre_16_7ms': raster.where((x) => x > 16.7).length,
    };

    // 4. Procesamiento de datos: decodificar y transformar 100 sesiones ×50
    //    (lo que hace la app con cada respuesta del historial) y sumar minutos.
    final cuerpo = (await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/focus-sessions?limit=100'),
      headers: {'Authorization': 'Bearer ${state.authentication!.token}'},
    )).body;
    await fase('procesamiento', () async {
      final t = <num>[];
      var minutos = 0;
      for (var i = 0; i < 50; i++) {
        final sw = Stopwatch()..start();
        final lista = (jsonDecode(cuerpo) as List)
            .cast<Map>()
            .map((m) => FocusSession.fromJson(m.cast<String, dynamic>()))
            .toList();
        minutos = lista.fold<int>(0, (s, x) => s + x.durationSeconds) ~/ 60;
        t.add(sw.elapsedMicroseconds / 1000);
        await Future<void>.delayed(Duration.zero);
      }
      datos['procesar_100_sesiones_ms'] = _stats(t);
      datos['procesar_bytes'] = cuerpo.length;
      datos['procesar_minutos'] = minutos;
    });

    // 5. Sesión de enfoque en curso con la app en reposo en Inicio (20 s):
    //    el temporizador avanza cada segundo; se mide cuánto se reconstruye.
    await tester.tap(find.byIcon(Icons.grid_view_rounded).last);
    await tester.pumpAndSettle();
    state.startSession(catalog.first, 25);
    await tester.pump();
    final cuadrosReposo = <FrameTiming>[];
    void alRecibir2(List<FrameTiming> t) => cuadrosReposo.addAll(t);
    SchedulerBinding.instance.addTimingsCallback(alRecibir2);
    await fase('sesion_en_curso_reposo', () async {
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 500));
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
    });
    SchedulerBinding.instance.removeTimingsCallback(alRecibir2);
    final b2 = cuadrosReposo.map((c) => ms(c.buildDuration)).toList();
    datos['reposo_cuadros'] = {'cuadros': cuadrosReposo.length, 'build_ms': _stats(b2), 'build_total_ms': b2.fold<double>(0, (a, b) => a + b)};
    await state.finishSession();
    await tester.pumpWidget(const SizedBox());
    await Future<void>.delayed(const Duration(seconds: 3)); // memoria final

    binding.reportData = {'fases': fases, 'datos': datos, 'api': AppConfig.apiBaseUrl};
    state.dispose();
  });
}

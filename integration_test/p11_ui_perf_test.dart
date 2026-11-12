// Práctica 11 · WB-06 Rendimiento de interfaz en el teléfono (modo profile).
//
//   flutter drive --profile -d <id> --driver=test_driver/p11_perf_driver.dart \
//     --target=integration_test/p11_ui_perf_test.dart \
//     --dart-define=CEOSMOS_API_URL=http://localhost:8080/api \
//     --dart-define=E2E_EMAIL=... --dart-define=E2E_PASSWORD=...
//
// Recorre las pestañas reales de CEOSMOS con datos de la API y mide los tiempos
// de construcción (UI thread) y de rasterizado por cuadro (FrameTiming del motor).
import 'package:ceosmos_movil_integral/app.dart';
import 'package:ceosmos_movil_integral/core/app_state.dart';
import 'package:ceosmos_movil_integral/core/config.dart';
import 'package:ceosmos_movil_integral/data/api_client.dart';
import 'package:ceosmos_movil_integral/data/auth_repository.dart';
import 'package:ceosmos_movil_integral/data/ceosmos_repository.dart';
import 'package:ceosmos_movil_integral/data/token_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const _email = String.fromEnvironment('E2E_EMAIL');
const _password = String.fromEnvironment('E2E_PASSWORD');

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('WB-06: navegación y desplazamiento con datos reales', (tester) async {
    final api = ApiClient(baseUrl: AppConfig.apiBaseUrl);
    final state = AppState(auth: AuthRepository(api, MemoryTokenStore()), data: CeosmosRepository(api));
    final sw = Stopwatch()..start();
    await state.acceptSession(await state.auth.login(_email, _password));
    final cargaMs = sw.elapsedMilliseconds; // login + 4 lecturas en paralelo
    await tester.pumpWidget(CeosmosApp(state: state));
    await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 20));

    Future<void> desplazar() async {
      final s = find.byType(Scrollable).first;
      for (var i = 0; i < 3; i++) {
        await tester.fling(s, const Offset(0, -600), 2500);
        await tester.pumpAndSettle();
      }
      await tester.fling(s, const Offset(0, 1800), 3000);
      await tester.pumpAndSettle();
    }

    // watchPerformance necesita el VM Service, que no fue accesible desde el S24;
    // se usan los FrameTiming que entrega el motor por cada cuadro dibujado.
    final cuadros = <FrameTiming>[];
    void alRecibir(List<FrameTiming> t) => cuadros.addAll(t);
    SchedulerBinding.instance.addTimingsCallback(alRecibir);
    final total = Stopwatch()..start();
    await (() async {
      for (final icono in [
        Icons.explore_outlined, Icons.timelapse_rounded, Icons.devices_other_outlined,
        Icons.person_outline_rounded, Icons.grid_view_rounded,
      ]) {
        await tester.tap(find.byIcon(icono).last);
        await tester.pumpAndSettle();
        await desplazar();
      }
    })();
    await tester.pump(const Duration(seconds: 1));
    total.stop();
    SchedulerBinding.instance.removeTimingsCallback(alRecibir);
    double ms(Duration d) => d.inMicroseconds / 1000;
    Map<String, double> stats(List<double> v) {
      final s = [...v]..sort();
      double p(double q) => s[((q / 100) * (s.length - 1)).round()];
      return {
        'promedio_ms': s.reduce((a, b) => a + b) / s.length,
        'p50_ms': p(50), 'p90_ms': p(90), 'p99_ms': p(99), 'max_ms': s.last,
      };
    }
    final build = cuadros.map((c) => ms(c.buildDuration)).toList();
    final raster = cuadros.map((c) => ms(c.rasterDuration)).toList();
    final presupuesto = 1000 / 120; // pantalla del S24 a 120 Hz
    binding.reportData = {
      'cuadros': cuadros.length,
      'duracion_s': total.elapsedMilliseconds / 1000,
      'build': stats(build),
      'raster': stats(raster),
      'presupuesto_ms_120hz': presupuesto,
      'cuadros_build_sobre_presupuesto': build.where((x) => x > presupuesto).length,
      'cuadros_raster_sobre_presupuesto': raster.where((x) => x > presupuesto).length,
      'cuadros_build_sobre_16_7ms': build.where((x) => x > 16.7).length,
      'cuadros_raster_sobre_16_7ms': raster.where((x) => x > 16.7).length,
      'carga_inicial_ms': cargaMs,
      'sesiones_en_historial': state.workspace.history.length,
    };
    state.dispose();
  });
}

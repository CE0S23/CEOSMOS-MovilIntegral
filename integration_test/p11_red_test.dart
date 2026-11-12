// Práctica 11 · Fase 5: conectividad y rendimiento medidos DESDE EL TELÉFONO.
//
//   flutter test integration_test/p11_red_test.dart -d <id> \
//     --dart-define=CEOSMOS_API_URL=http://localhost:8080/api \
//     --dart-define=E2E_EMAIL=... --dart-define=E2E_PASSWORD=...
//
// La API local se alcanza por `adb reverse tcp:8080` (USB). El sitio web de
// CEOSMOS (Vercel) se alcanza por la red real del teléfono (Wi-Fi + Internet).
// Cada medición se imprime como una línea `P11_JSON {...}`; la prueba de
// interrupción imprime `P11_MARK CORTAR` / `P11_MARK RECONECTAR` para que el
// script del equipo quite y vuelva a poner el `adb reverse`.
import 'dart:convert';
import 'dart:io';

import 'package:ceosmos_movil_integral/core/app_state.dart';
import 'package:ceosmos_movil_integral/core/config.dart';
import 'package:ceosmos_movil_integral/data/api_client.dart';
import 'package:ceosmos_movil_integral/data/auth_repository.dart';
import 'package:ceosmos_movil_integral/data/catalog.dart';
import 'package:ceosmos_movil_integral/data/ceosmos_repository.dart';
import 'package:ceosmos_movil_integral/data/token_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:integration_test/integration_test.dart';

const _email = String.fromEnvironment('E2E_EMAIL');
const _password = String.fromEnvironment('E2E_PASSWORD');
const _web = 'https://ceosmos-t8ee.vercel.app';

void _json(String tipo, Map<String, Object?> datos) =>
    // ignore: avoid_print
    print('P11_JSON ${jsonEncode({'tipo': tipo, ...datos})}');

// ignore: avoid_print
void _mark(String m) => print('P11_MARK $m');

double _mbps(int bytes, int micros) => (bytes * 8) / (micros / 1e6) / 1e6;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('P11 red: latencia, transferencia e interrupción desde el S24', (tester) async {
    expect(_email, isNotEmpty, reason: 'Define E2E_EMAIL y E2E_PASSWORD');
    _json('entorno', {
      'fecha': DateTime.now().toIso8601String(),
      'so': Platform.operatingSystem,
      'version_so': Platform.operatingSystemVersion,
      'api': AppConfig.apiBaseUrl,
      'app': 'ceosmos_movil_integral 1.1.0+2 (debug, integration_test)',
    });

    // Sin conexiones persistentes, para que el corte del enlace se note en la
    // siguiente petición (la app normal reutiliza la conexión: keep-alive).
    final io = HttpClient()..idleTimeout = const Duration(milliseconds: 1);
    final api = ApiClient(baseUrl: AppConfig.apiBaseUrl, client: IOClient(io));
    final state = AppState(
      auth: AuthRepository(api, MemoryTokenStore()),
      data: CeosmosRepository(api),
      startTicker: false,
    );
    addTearDown(state.dispose);
    await state.acceptSession(await state.auth.login(_email, _password));
    final token = state.authentication!.token;

    // ---- B / D: 10 solicitudes consecutivas al mismo endpoint -----------------
    final cliente = http.Client();
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/focus-sessions?limit=50');
    for (var i = 1; i <= 10; i++) {
      final sw = Stopwatch()..start();
      final r = await cliente.get(uri, headers: {'Authorization': 'Bearer $token'});
      sw.stop();
      _json('http_10', {
        'n': i, 'endpoint': 'GET /api/focus-sessions?limit=50', 'status': r.statusCode,
        'ms': sw.elapsedMicroseconds / 1000, 'bytes': r.bodyBytes.length,
        'items': (jsonDecode(r.body) as List).length,
      });
    }

    // ---- C: descarga (3) desde la API local y desde el sitio web real ---------
    final grande = Uri.parse('${AppConfig.apiBaseUrl}/focus-sessions?limit=100');
    for (var i = 1; i <= 3; i++) {
      final sw = Stopwatch()..start();
      final r = await cliente.get(grande, headers: {'Authorization': 'Bearer $token'});
      sw.stop();
      _json('descarga', {
        'n': i, 'origen': 'API local (USB, adb reverse)', 'recurso': 'GET /api/focus-sessions?limit=100',
        'status': r.statusCode, 'bytes': r.bodyBytes.length, 's': sw.elapsedMicroseconds / 1e6,
        'mbps': _mbps(r.bodyBytes.length, sw.elapsedMicroseconds),
      });
    }
    final html = await cliente.get(Uri.parse(_web));
    final mainJs = RegExp(r'src="(main\.[0-9a-f]+\.js)"').firstMatch(html.body)!.group(1)!;
    for (var i = 1; i <= 3; i++) {
      final sw = Stopwatch()..start();
      final r = await http.get(Uri.parse('$_web/$mainJs'), headers: {'Cache-Control': 'no-cache'});
      sw.stop();
      _json('descarga', {
        'n': i, 'origen': 'Sitio web CEOSMOS (Vercel, Wi-Fi + Internet)', 'recurso': mainJs,
        'status': r.statusCode, 'bytes': r.bodyBytes.length, 's': sw.elapsedMicroseconds / 1e6,
        'mbps': _mbps(r.bodyBytes.length, sw.elapsedMicroseconds),
      });
    }

    // ---- C: subida (3) -------------------------------------------------------
    // Tras la corrección P11-D04 la API acepta metadata de hasta 4 KB: se mide la
    // subida con el cuerpo máximo permitido y se comprueba que 100 KB se rechazan.
    final ahora = DateTime.now().toUtc();
    String cuerpo(int i, int muestras) => jsonEncode({
      'contentKey': 'orbit', 'mode': 'FOCUS',
      'startedAt': ahora.subtract(Duration(minutes: 30 + i)).toIso8601String(),
      'endedAt': ahora.subtract(Duration(minutes: 5 + i)).toIso8601String(),
      'durationSeconds': 1500, 'targetMinutes': 25, 'completed': true,
      'metadata': {'source': 'p11-subida', 'muestras': List.generate(muestras, (k) => 60 + k % 40)},
    });
    Future<(int, int, int)> enviar(String c) async {
      final sw = Stopwatch()..start();
      final r = await cliente.post(
        Uri.parse('${AppConfig.apiBaseUrl}/focus-sessions'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: c,
      );
      sw.stop();
      return (r.statusCode, utf8.encode(c).length, sw.elapsedMicroseconds);
    }

    final (rechazo, bytesGrandes, _) = await enviar(cuerpo(0, 30000)); // ~100 KB
    _json('metadata_grande', {'bytes': bytesGrandes, 'status': rechazo});
    expect(rechazo, 400, reason: 'P11-D04: metadata > 4 KB debe rechazarse');
    for (var i = 1; i <= 3; i++) {
      final (status, bytes, us) = await enviar(cuerpo(i, 1250)); // metadata ≈ 3.8 KB
      _json('subida', {
        'n': i, 'destino': 'POST /api/focus-sessions (USB, adb reverse)', 'status': status,
        'bytes': bytes, 's': us / 1e6, 'mbps': _mbps(bytes, us),
      });
      expect(status, 201);
    }

    // ---- E: interrupción de la conexión app ↔ API -----------------------------
    final t0 = DateTime.now().subtract(const Duration(seconds: 5));
    Future<int> recientes() async =>
        (await state.data.focusSessions(limit: 20)).where((s) => s.startedAt.isAfter(t0)).length;
    final antes = await recientes();
    state.startSession(catalog.first, 5);
    await Future<void>.delayed(const Duration(seconds: 3));

    _mark('CORTAR');
    final corte = Stopwatch()..start();
    var sinRed = false;
    while (!sinRed && corte.elapsed < const Duration(seconds: 60)) {
      try {
        await api.get('/users/me');
        await Future<void>.delayed(const Duration(milliseconds: 500));
      } on ApiException {
        sinRed = true;
      }
    }
    expect(sinRed, isTrue, reason: 'no se detectó el corte');
    final det = Stopwatch()..start();
    await state.finishSession(); // operación con la red caída
    det.stop();
    final aviso = state.takeNotice();
    _json('interrupcion', {
      'detectado': state.pendingSessions == 1,
      'ms_hasta_error': det.elapsedMicroseconds / 1000,
      'mostrada_como_guardada': state.workspace.history.first.synced,
      'pendientes': state.pendingSessions,
      'aviso': aviso,
    });
    expect(state.pendingSessions, 1);
    expect(state.workspace.history.first.synced, isFalse);

    await state.loadWorkspace(); // reintento sin red: no debe perder la sesión
    _json('reintento_sin_red', {'pendientes': state.pendingSessions, 'error': state.dataError});

    _mark('RECONECTAR');
    final rec = Stopwatch()..start();
    var conRed = false;
    while (!conRed && rec.elapsed < const Duration(seconds: 60)) {
      try {
        await api.get('/users/me');
        conRed = true;
      } on ApiException {
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
    }
    expect(conRed, isTrue, reason: 'no volvió la conexión');
    await state.loadWorkspace(); // reenvío controlado de la cola
    final despues = await recientes();
    _json('recuperacion', {
      's_hasta_reconectar': rec.elapsedMilliseconds / 1000,
      'pendientes': state.pendingSessions,
      'sesiones_antes': antes, 'sesiones_despues': despues,
      'duplicados': despues - antes - 1,
      'sincronizada': state.workspace.history.first.synced,
    });
    expect(state.pendingSessions, 0);
    expect(despues, antes + 1);

    cliente.close();
    await state.signOut();
  }, timeout: const Timeout(Duration(minutes: 6)));
}

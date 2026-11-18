// Práctica 12 · Fase 5: pruebas de resiliencia y recuperación EN EL DISPOSITIVO.
//
//   node p11yp12/p12/scripts/fase5_proxy_fallos.js <log> emulator-5554   (en el equipo)
//   flutter test integration_test/p12_resiliencia_test.dart -d emulator-5554 \
//     --dart-define=CEOSMOS_API_URL=http://10.0.2.2:8081/api \
//     --dart-define=E2E_EMAIL=... --dart-define=E2E_PASSWORD=...
//
// La app real (AppState + ApiClient de producción) habla con la API local a través del
// proxy de fallos (puerto 8081). La prueba controla el proxy por el puerto 8082 y, para
// las pérdidas de Internet, activa el modo avión REAL del emulador durante unos segundos.
// Cada escenario imprime una línea `P12_RES {...}` con lo observado. La prueba no se
// detiene en el primer fallo: registra el resultado de los 9 escenarios.
import 'dart:convert';

import 'package:ceosmos_movil_integral/core/app_state.dart';
import 'package:ceosmos_movil_integral/core/config.dart';
import 'package:ceosmos_movil_integral/data/api_client.dart';
import 'package:ceosmos_movil_integral/data/auth_repository.dart';
import 'package:ceosmos_movil_integral/data/catalog.dart';
import 'package:ceosmos_movil_integral/data/ceosmos_repository.dart';
import 'package:ceosmos_movil_integral/data/token_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';

const _email = String.fromEnvironment('E2E_EMAIL');
const _password = String.fromEnvironment('E2E_PASSWORD');
const _control = 'http://10.0.2.2:8082';

void _res(String codigo, Map<String, Object?> datos) =>
    // ignore: avoid_print
    print('P12_RES ${jsonEncode({'codigo': codigo, ...datos})}');

Future<Map<String, dynamic>> _modo(String q) async =>
    jsonDecode((await http.get(Uri.parse('$_control/modo?$q'))).body) as Map<String, dynamic>;

Future<List<Map<String, dynamic>>> _registro(int desde) async =>
    (jsonDecode((await http.get(Uri.parse('$_control/registro?desde=$desde'))).body) as List)
        .cast<Map<String, dynamic>>();

/// Espera a que vuelva la red (el panel del proxy responde). Devuelve los ms esperados.
Future<int> _esperarRed() async {
  final sw = Stopwatch()..start();
  while (sw.elapsed < const Duration(seconds: 60)) {
    try {
      await http.get(Uri.parse('$_control/registro?desde=${DateTime.now().millisecondsSinceEpoch}'))
          .timeout(const Duration(seconds: 2));
      return sw.elapsedMilliseconds;
    } on Object {
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
  }
  return -1;
}

int _ahora() => DateTime.now().millisecondsSinceEpoch;

/// Hora del EQUIPO (el reloj del emulador puede ir desfasado): se usa para filtrar el
/// registro del proxy, que anota sus eventos con la hora del equipo.
Future<int> _marca() async =>
    ((jsonDecode((await http.get(Uri.parse('$_control/marca'))).body) as Map)['ms'] as num).toInt();

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('P12 resiliencia RES-01…RES-09', (tester) async {
    expect(_email, isNotEmpty, reason: 'Define E2E_EMAIL y E2E_PASSWORD');
    final api = ApiClient(baseUrl: AppConfig.apiBaseUrl);
    final state = AppState(auth: AuthRepository(api, MemoryTokenStore()), data: CeosmosRepository(api), startTicker: false);
    addTearDown(state.dispose);
    await _modo('m=normal');
    await state.acceptSession(await state.auth.login(_email, _password));
    final base = state.workspace.history.length;
    _res('inicio', {'api': AppConfig.apiBaseUrl, 'historial': base, 'fecha': DateTime.now().toIso8601String()});

    Future<int> sesionesServidor(String clientId) async {
      final l = await state.data.focusSessions(limit: 100);
      return l.where((s) => s.clientId == clientId).length;
    }

    // ---- RES-01 Pérdida de Internet durante una consulta ----------------------
    {
      await _modo('m=lento&ms=2500&ruta=/focus-sessions&metodo=GET&veces=1');
      final previo = state.workspace.history.length;
      final m0 = await _marca();
      await http.get(Uri.parse('$_control/avion?s=20&tras=700'));
      final t0 = _ahora();
      await state.loadWorkspace();
      final detecta = _ahora() - t0;
      final error = state.dataError;
      final red = await _esperarRed();
      final ev = await _registro(m0);
      final on = ev.firstWhere((e) => e['evento'] == 'avion_on', orElse: () => {})['ms'] as int?;
      _res('RES-01', {
        'escenario': 'Pérdida de Internet durante una consulta (historial retenido 2.5 s; avión 20 s desde los 0.7 s)',
        'ms_hasta_error_desde_inicio': detecta,
        'ms_hasta_error_desde_corte': on == null ? null : m0 + detecta - on,
        'error_mostrado': error,
        'sigue_con_sesion': state.status == AuthStatus.signedIn,
        'historial_conservado': state.workspace.history.length == previo,
        'ms_hasta_volver_red': red,
      });
      await _modo('m=normal');
      await state.loadWorkspace();
    }

    // ---- RES-02 Pérdida de Internet durante una escritura ---------------------
    String? clientIdRes02;
    {
      await _modo('m=lento&ms=2500&ruta=/focus-sessions&metodo=POST&veces=1');
      state.startSession(catalog.first, 5);
      await http.get(Uri.parse('$_control/avion?s=20&tras=700'));
      final t0 = _ahora();
      await state.finishSession();
      final detecta = _ahora() - t0;
      final local = state.workspace.history.first;
      clientIdRes02 = local.clientId;
      final aviso = state.takeNotice();
      final pendientes = state.pendingSessions;
      final red = await _esperarRed();
      await Future<void>.delayed(const Duration(seconds: 2));
      final enServidor = await sesionesServidor(clientIdRes02!);
      _res('RES-02', {
        'escenario': 'Pérdida de Internet durante una escritura (POST retenido 2.5 s; avión 20 s desde los 0.7 s)',
        'ms_hasta_resultado': detecta,
        'marcada_como_guardada': state.workspace.history.any((s) => s.clientId == clientIdRes02 && s.synced),
        'pendientes': pendientes,
        'aviso': aviso,
        'ms_hasta_volver_red': red,
        'filas_en_servidor_con_ese_clientId_antes_de_reintentar': enServidor,
        'nota': 'el proxy entregó el POST al servidor aunque el teléfono ya no esperaba la respuesta',
      });
    }

    // ---- RES-06 Recuperación de la conexión (sin intervención del usuario) ---
    {
      final t0 = _ahora();
      var auto = -1;
      for (var i = 0; i < 40; i++) {
        if (state.pendingSessions == 0) {
          auto = _ahora() - t0;
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
      final pendientesSinAccion = state.pendingSessions;
      final t1 = _ahora();
      await state.loadWorkspace(); // el usuario pulsa «Actualizar»
      final manual = _ahora() - t1;
      final enServidor = await sesionesServidor(clientIdRes02);
      final enHistorial = state.workspace.history.where((s) => s.clientId == clientIdRes02).length;
      _res('RES-06', {
        'escenario': 'Recuperación de la conexión tras RES-02',
        'se_envio_sola_ms': auto, // -1 = no se reenvió sin intervención en 20 s
        'pendientes_tras_20s_sin_accion': pendientesSinAccion,
        'ms_recarga_manual': manual,
        'pendientes_final': state.pendingSessions,
        'error_final': state.dataError,
        'filas_en_servidor_con_ese_clientId': enServidor,
        'veces_en_historial_de_la_app': enHistorial,
      });
    }

    // ---- RES-03 Servidor sin respuesta ---------------------------------------
    {
      await _modo('m=colgar&ruta=/focus-sessions&metodo=GET&veces=1');
      final t0 = _ahora();
      await state.loadWorkspace();
      final ms = _ahora() - t0;
      _res('RES-03', {
        'escenario': 'Servidor acepta la conexión pero nunca responde',
        'ms_hasta_error': ms, 'error_mostrado': state.dataError,
        'sigue_con_sesion': state.status == AuthStatus.signedIn, 'cargando': state.loadingData,
      });
      await _modo('m=normal');
    }

    // ---- RES-04 Respuesta HTTP 500 -------------------------------------------
    {
      await _modo('m=http500&ruta=/favorites&metodo=GET&veces=1');
      final previo = state.workspace.history.length;
      await state.loadWorkspace();
      final error = state.dataError;
      final estable = state.status == AuthStatus.signedIn && state.workspace.history.length == previo;
      await _modo('m=http500&ruta=/focus-sessions&metodo=POST&veces=1');
      state.startSession(catalog.first, 5);
      await state.finishSession();
      final aviso = state.takeNotice();
      final pend = state.pendingSessions;
      await _modo('m=normal');
      await state.loadWorkspace();
      _res('RES-04', {
        'escenario': 'HTTP 500 en una lectura y en una escritura',
        'error_lectura': error, 'estado_estable': estable,
        'aviso_escritura': aviso, 'pendientes_tras_500': pend,
        'tras_recargar_error': state.dataError, 'pendientes_final': state.pendingSessions,
      });
    }

    // ---- RES-05 Respuestas 403 y 401 ------------------------------------------
    {
      await _modo('m=http403&ruta=/devices&metodo=GET&veces=1');
      await state.loadWorkspace();
      final e403 = state.dataError;
      final con403 = state.status == AuthStatus.signedIn;
      await _modo('m=http401&ruta=/favorites&metodo=GET&veces=1');
      await state.loadWorkspace();
      final e401 = state.status;
      final aviso401 = state.notice;
      final tokenBorrado = api.token == null;
      await _modo('m=normal');
      await state.acceptSession(await state.auth.login(_email, _password));
      _res('RES-05', {
        'escenario': '403 en /devices y 401 en /favorites',
        'mensaje_403': e403, 'sigue_con_sesion_tras_403': con403,
        'estado_tras_401': e401.name, 'aviso_401': aviso401, 'token_borrado': tokenBorrado,
        'reingreso_ok': state.status == AuthStatus.signedIn,
      });
    }

    // ---- RES-07 Reintento de una escritura (respuesta perdida) ----------------
    {
      await _modo('m=perder_respuesta&ruta=/focus-sessions&metodo=POST&veces=1');
      final t0 = await _marca();
      state.startSession(catalog.first, 5);
      await state.finishSession();
      final cid = state.workspace.history.first.clientId!;
      final pend = state.pendingSessions;
      state.takeNotice();
      await _modo('m=normal');
      // Se da tiempo a un reintento automático; si no existe, el usuario recarga.
      for (var i = 0; i < 24 && state.pendingSessions > 0; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
      final auto = state.pendingSessions == 0;
      await state.loadWorkspace();
      final posts = (await _registro(t0)).where((e) => e['metodo'] == 'POST' && e['clientId'] == cid).length;
      _res('RES-07', {
        'escenario': 'El servidor guarda la sesión pero la respuesta se pierde; la app reintenta',
        'pendientes_tras_fallo': pend, 'reintento_automatico': auto,
        'post_enviados_con_el_mismo_clientId': posts,
        'filas_en_servidor': await sesionesServidor(cid),
        'veces_en_historial_de_la_app': state.workspace.history.where((s) => s.clientId == cid).length,
      });
    }

    // ---- RES-08 Respuesta tardía: doble pulsación y doble recarga -------------
    {
      await _modo('m=lento&ms=3000&ruta=/focus-sessions&metodo=POST&veces=1');
      final t0 = await _marca();
      state.startSession(catalog.first, 5);
      final f1 = state.finishSession();
      final f2 = state.finishSession(); // segunda pulsación de «Terminar» mientras espera
      await Future.wait([f1, f2]);
      final cid = state.workspace.history.first.clientId!;
      await _modo('m=lento&ms=2000&ruta=/focus-sessions&metodo=GET');
      final t1 = await _marca();
      final d0 = _ahora();
      await Future.wait([state.loadWorkspace(), state.loadWorkspace()]); // doble «Actualizar»
      final dur = _ahora() - d0;
      await _modo('m=normal');
      final reg = await _registro(t0);
      final ids = state.workspace.history.map((s) => s.id).toList();
      _res('RES-08', {
        'escenario': 'Respuesta tardía (3 s POST, 2 s GET) con doble pulsación y doble recarga',
        'post_enviados': reg.where((e) => e['metodo'] == 'POST').length,
        'get_historial_enviados_en_doble_recarga': reg.where((e) => e['metodo'] == 'GET' && (e['ms'] as int) >= t1 && (e['ruta'] as String).startsWith('/api/focus-sessions')).length,
        'get_totales_en_doble_recarga': reg.where((e) => e['metodo'] == 'GET' && (e['ms'] as int) >= t1).length,
        'ms_doble_recarga': dur,
        'filas_en_servidor': await sesionesServidor(cid),
        'ids_duplicados_en_historial': ids.length - ids.toSet().length,
      });
    }

    // ---- RES-09 (adicional) Escritura pendiente que el servidor rechaza (400) --
    {
      await _modo('m=cortar&ruta=/focus-sessions&metodo=POST&veces=1');
      state.startSession(catalog.first, 5);
      await state.finishSession(); // queda pendiente
      state.takeNotice();
      await _modo('m=http400&ruta=/focus-sessions&metodo=POST');
      await state.loadWorkspace();
      final e1 = state.dataError;
      await state.loadWorkspace();
      final e2 = state.dataError;
      final pend = state.pendingSessions;
      await _modo('m=normal');
      await state.loadWorkspace();
      _res('RES-09', {
        'escenario': 'Una sesión pendiente es rechazada con 400 en cada reintento',
        'error_carga_1': e1, 'error_carga_2': e2, 'pendientes': pend,
        'aviso': state.takeNotice(),
        'datos_cargan_al_final': state.dataError == null,
        'pendientes_final': state.pendingSessions,
      });
    }
    await _modo('m=normal');
  }, timeout: const Timeout(Duration(minutes: 8)));
}

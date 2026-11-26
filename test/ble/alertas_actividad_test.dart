// 1.4.0 · Simulación de actividades (campo `act`), reglas de alerta de salud,
// entrega al Reloj y a la TV, registro en la sesión y robustez GATT del central.
import 'dart:convert';

import 'package:ceosmos_movil_integral/core/alertas_salud.dart';
import 'package:ceosmos_movil_integral/core/app_state.dart';
import 'package:ceosmos_movil_integral/core/ble/ble_protocolo.dart';
import 'package:ceosmos_movil_integral/core/ble/ecosistema_ble.dart';
import 'package:ceosmos_movil_integral/core/wearable.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_ble.dart';
import '../support/fake_ceosmos_api.dart';

List<int> _b(Object o) => utf8.encode(jsonEncode(o));

Future<void> esperar([int ms = 20]) => Future<void>.delayed(Duration(milliseconds: ms));

Future<void> esperarHasta(bool Function() condicion, {int maxMs = 3000}) async {
  final reloj = Stopwatch()..start();
  while (!condicion() && reloj.elapsedMilliseconds < maxMs) {
    await esperar(10);
  }
}

class _NotificadorEspia implements NotificadorAlertas {
  final mostradas = <AlertaSalud>[];
  bool concedido = true;
  @override
  Future<bool> pedirPermiso() async => concedido;
  @override
  Future<void> mostrar(AlertaSalud a) async => mostradas.add(a);
}

void main() {
  final t0 = DateTime(2026, 11, 26, 10);
  DateTime seg(int s) => t0.add(Duration(seconds: s));

  group('Protocolo · campo act', () {
    test('lectura con actividad válida', () {
      final m = decodificar(_b({'t': 'hr', 'hr': 150, 'steps': 10, 'act': 'corriendo'}), RolBle.reloj);
      expect(m, isA<LecturaReloj>().having((l) => l.actividad, 'act', 'corriendo'));
    });

    test('compatible hacia atrás: sin act o con act desconocida sigue siendo lectura', () {
      final sin = decodificar(_b({'t': 'hr', 'hr': 70, 'steps': 1}), RolBle.reloj) as LecturaReloj;
      expect(sin.actividad, isNull);
      final otra = decodificar(_b({'t': 'hr', 'hr': 70, 'act': 'nadando'}), RolBle.reloj) as LecturaReloj;
      expect(otra.actividad, isNull);
      expect(otra.hr, 70);
    });

    test('mismo vector que Kotlin cabe en 180 bytes y el rango 30–230 se mantiene', () {
      final bytes = _b({'t': 'hr', 'hr': 230, 'steps': 1000000, 'act': 'durmiendo'});
      expect(bytes.length, lessThanOrEqualTo(maxBytesMensaje));
      expect(decodificar(_b({'t': 'hr', 'hr': 231, 'act': 'reposo'}), RolBle.reloj), isNull);
      expect(decodificar(_b({'t': 'hr', 'hr': 29, 'act': 'reposo'}), RolBle.reloj), isNull);
    });

    test('la alerta para Reloj y TV cabe en 180 bytes', () {
      final a = AlertaSalud(tipo: TipoAlerta.pulsoAlto, hr: 165, actividad: 'caminando', at: t0);
      final bytes = codificar({'t': 'alert', 'lvl': 'aviso', 'msg': a.texto});
      expect(bytes.length, lessThanOrEqualTo(maxBytesMensaje));
      expect(a.texto.length, lessThanOrEqualTo(120));
    });
  });

  group('Reglas de alerta', () {
    test('pulso alto en reposo sostenido ~10 s alerta; antes no', () {
      final m = MotorAlertas();
      for (var s = 0; s < 10; s++) {
        expect(m.evaluar(160, 'reposo', seg(s)), isNull, reason: 's=$s');
      }
      expect(m.evaluar(160, 'reposo', seg(10))?.tipo, TipoAlerta.pulsoAlto);
    });

    test('correr con pulso de correr NO alerta', () {
      final m = MotorAlertas();
      for (var s = 0; s < 120; s++) {
        expect(m.evaluar(150 + s % 28, 'corriendo', seg(s)), isNull);
      }
      for (var s = 0; s < 60; s++) {
        expect(m.evaluar(120 + s % 25, 'trotando', seg(200 + s)), isNull);
      }
    });

    test('pulso muy alto en cualquier actividad (sostenido 3 s) es urgente', () {
      final m = MotorAlertas();
      expect(m.evaluar(190, 'corriendo', seg(0)), isNull);
      final a = m.evaluar(190, 'corriendo', seg(3));
      expect(a?.tipo, TipoAlerta.pulsoMuyAlto);
      expect(a!.urgente, isTrue);
    });

    test('pulso bajo despierto alerta; durmiendo no', () {
      final m = MotorAlertas();
      for (var s = 0; s <= 12; s++) {
        expect(m.evaluar(40, 'durmiendo', seg(s)), isNull);
      }
      AlertaSalud? a;
      for (var s = 20; s <= 30; s++) {
        a ??= m.evaluar(40, 'reposo', seg(s));
      }
      expect(a?.tipo, TipoAlerta.pulsoBajo);
    });

    test('una lectura normal reinicia el conteo sostenido', () {
      final m = MotorAlertas();
      for (var s = 0; s < 9; s++) {
        m.evaluar(160, 'reposo', seg(s));
      }
      expect(m.evaluar(70, 'reposo', seg(9)), isNull);
      expect(m.evaluar(160, 'reposo', seg(10)), isNull, reason: 'vuelve a empezar');
    });

    test('enfriamiento de 60 s por tipo y tope por sesión', () {
      final m = MotorAlertas(topePorSesion: 2);
      var emitidas = 0;
      for (var s = 0; s < 200; s++) {
        if (m.evaluar(160, 'reposo', seg(s)) != null) emitidas++;
        if (s == 59) expect(emitidas, 1, reason: 'una sola en el primer minuto');
      }
      expect(emitidas, 2, reason: 'tope por sesión');
      m.reiniciarSesion();
      AlertaSalud? otra;
      for (var s = 300; s <= 310; s++) {
        otra ??= m.evaluar(160, 'reposo', seg(s));
      }
      expect(otra, isNotNull);
    });

    test('sin actividad (Reloj antiguo) solo aplican muy alto y bajo', () {
      expect(MotorAlertas.condiciones(160, null), isEmpty);
      expect(MotorAlertas.condiciones(190, null), {TipoAlerta.pulsoMuyAlto});
      expect(MotorAlertas.condiciones(40, null), {TipoAlerta.pulsoBajo});
      expect(MotorAlertas.condiciones(140, 'caminando'), {TipoAlerta.pulsoAlto});
      expect(MotorAlertas.condiciones(140, 'trotando'), isEmpty);
    });
  });

  group('Entrega y registro', () {
    late PerifericoFalso tablet;
    late EcosistemaBle ble;
    late AppState state;
    late _NotificadorEspia notif;

    setUp(() async {
      tablet = PerifericoFalso(remoteId: 'AA:BB:CC:00:11:22', id: 'ab0102ff');
      ble = EcosistemaBle(transporte: TransporteFalso([tablet]), esperaBase: const Duration(milliseconds: 5));
      notif = _NotificadorEspia();
      final base = FakeCeosmosApi().appState();
      state = AppState(
        auth: base.auth,
        data: base.data,
        ble: ble,
        startTicker: false,
        notificador: notif,
        motorAlertas: MotorAlertas(sostenido: Duration.zero, sostenidoMuyAlto: Duration.zero),
      );
      await ble.conectar(RolBle.reloj, pin: '123456');
      await ble.conectar(RolBle.tv, pin: '123456');
    });
    tearDown(() => state.dispose());

    test('alerta → notificación, aviso interno, Reloj, TV y conteo de sesión', () async {
      tablet.enviar(RolBle.reloj, {'t': 'hr', 'hr': 170, 'steps': 5, 'act': 'reposo'});
      await esperarHasta(() => (tablet.recibidos[RolBle.tv] ?? []).any((m) => m['t'] == 'alert'));
      expect(notif.mostradas.single.tipo, TipoAlerta.pulsoAlto);
      expect(state.alertaActiva?.hr, 170);
      expect(state.tomarAlertaNueva(), isNotNull);
      expect(state.tomarAlertaNueva(), isNull, reason: 'el aviso interno se muestra una vez');
      expect(tablet.recibidos[RolBle.reloj]!.where((m) => m['t'] == 'alert'), hasLength(1));
      expect(ble.alertasSesion, 1);
    });

    test('con el interruptor apagado no se alerta', () async {
      await state.setAlertasActivadas(false);
      tablet.enviar(RolBle.reloj, {'t': 'hr', 'hr': 200, 'act': 'reposo'});
      await esperar(30);
      expect(notif.mostradas, isEmpty);
      expect(state.alertaActiva, isNull);
    });

    test('resumen de sesión: tiempo por actividad, alertas y pulso máximo', () async {
      ble.marcarInicio();
      tablet.enviar(RolBle.reloj, {'t': 'hr', 'hr': 90, 'act': 'caminando'});
      await esperar(1100);
      tablet.enviar(RolBle.reloj, {'t': 'hr', 'hr': 160, 'act': 'corriendo'});
      await esperar(20);
      final w = ble.resumenSesion(deviceId: 'x')['wearable'] as Map;
      expect(w['maxHeartRate'], 160);
      expect((w['activitySeconds'] as Map)['corriendo'], greaterThanOrEqualTo(1));
      expect(w['alerts'], 0);
      expect(utf8.encode(jsonEncode(w)).length, lessThan(4096), reason: 'metadata ≤ 4096 bytes en la API');
    });
  });

  group('Robustez GATT del central', () {
    test('Reloj y TV en la misma tablet: nunca dos operaciones GATT a la vez', () async {
      final tablet = PerifericoFalso(remoteId: 'AA', id: 'ab0102ff');
      final ble = EcosistemaBle(transporte: TransporteFalso([tablet]));
      addTearDown(ble.dispose);
      await ble.conectar(RolBle.reloj, pin: '123456');
      await ble.conectar(RolBle.tv, pin: '123456');
      tablet.maxOpsEnVuelo = 0;
      await Future.wait([
        for (var i = 0; i < 20; i++) ...[
          ble.enviar(RolBle.reloj, {'t': 'notif', 'msg': 'r$i'}),
          ble.enviar(RolBle.tv, {'t': 'hello', 'name': 't$i'}),
        ],
      ]);
      expect(tablet.maxOpsEnVuelo, 1);
    });

    test('un fallo transitorio de escritura se reintenta y no se pierde el envío', () async {
      final tablet = PerifericoFalso(remoteId: 'AA', id: 'ab0102ff');
      final ble = EcosistemaBle(
        transporte: TransporteFalso([tablet]),
        esperaReintentoGatt: const Duration(milliseconds: 5),
      );
      addTearDown(ble.dispose);
      await ble.conectar(RolBle.tv, pin: '123456');
      tablet.fallosTransitorios = 1;
      expect(await ble.enviar(RolBle.tv, {'t': 'hello', 'name': 'x'}), isTrue);
      expect(ble.reintentosOk, 1);
      expect(ble[RolBle.tv].estado, EstadoEnlace.conectado);
    });

    test('Reloj que arranca después de que la TV abrió el enlace: se redescubren servicios', () async {
      final tablet = PerifericoFalso(remoteId: 'AA', id: 'ab0102ff', roles: {RolBle.tv});
      final ble = EcosistemaBle(transporte: TransporteFalso([tablet]));
      addTearDown(ble.dispose);
      expect(await ble.conectar(RolBle.tv, pin: '123456'), ResultadoConexion.conectado);
      tablet.roles.add(RolBle.reloj); // la app Reloj vuelve a anunciar en la misma tablet
      expect(await ble.conectar(RolBle.reloj, pin: '123456'), ResultadoConexion.conectado);
      expect(ble[RolBle.tv].estado, EstadoEnlace.conectado, reason: 'la TV no se corta');
    });

    test('WearableLectura conserva la actividad', () {
      final l = WearableLectura(heartRate: 70, at: t0, actividad: 'reposo');
      expect(l.actividad, 'reposo');
    });
  });
}

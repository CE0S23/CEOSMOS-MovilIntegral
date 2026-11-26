// 1.4.0 · Pone la tarjeta «Tu Reloj y TV» de Inicio en su estado más cargado:
// Reloj y TV conectados, lectura con pasos de 6 cifras, alerta activa y la TV
// proyectando una sesión. Lo usan el barrido de tamaños y la prueba de fuente al 200 %.
import 'package:ceosmos_movil_integral/core/alertas_salud.dart';
import 'package:ceosmos_movil_integral/core/app_state.dart';
import 'package:ceosmos_movil_integral/core/ble/ble_protocolo.dart';
import 'package:ceosmos_movil_integral/core/ble/ecosistema_ble.dart';
import 'package:ceosmos_movil_integral/data/catalog.dart';

import 'fake_ble.dart';

PerifericoFalso tabletDemo() => PerifericoFalso(remoteId: 'AA:BB:CC:00:11:22', id: 'ab0102ff');

EcosistemaBle bleDemo(PerifericoFalso tablet) => EcosistemaBle(transporte: TransporteFalso([tablet]));

/// Debe correr con datos reales (en pruebas de widgets, dentro de `tester.runAsync`).
Future<void> poblarEquipos(AppState state, PerifericoFalso tablet) async {
  await state.connectBle(RolBle.reloj, pin: '123456');
  await state.connectBle(RolBle.tv, pin: '123456');
  tablet.enviar(RolBle.reloj, {'t': 'hr', 'hr': 172, 'steps': 123456, 'act': 'caminando'});
  await Future<void>.delayed(const Duration(milliseconds: 5));
  state.alertaActiva = AlertaSalud(
    tipo: TipoAlerta.pulsoMuyAlto,
    hr: 192,
    actividad: 'caminando',
    at: DateTime.now(),
  );
  state.startSession(catalog.first, 25);
}

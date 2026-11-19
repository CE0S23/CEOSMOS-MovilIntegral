// P13-14 · Prueba de REGRESIÓN del defecto encontrado en hardware el 18/11/2026
// (S24 ↔ Galaxy Tab S9, ver memoria «06 - BLE Wearable y TV»):
//
//   DEF-BLE-01 «TV reiniciada seguía marcando Conectado». Con el Reloj y la TV en la
//   misma tablet, el enlace físico BLE es uno solo. Si la app TV se cierra y se abre,
//   su servidor GATT olvida la autenticación pero el enlace NO se cae (lo mantiene el
//   Reloj). CEOSMOS seguía mostrando la TV como «Conectado» y cada proyección de sesión
//   era rechazada con GATT_INSUFFICIENT_AUTHORIZATION: la TV quedaba congelada.
//
//   Corrección (commit 1a8f98c): `_autorizacionPerdida` → al recibir «sin autorización»
//   se suelta el rol y se reautentica con el PIN guardado.
//
// Con el código anterior (1a8f98c^) esta prueba FALLA; con el actual PASA. La
// demostración está en `evidencias/p13_14/regresion_codigo_viejo.txt` y
// `regresion_codigo_nuevo.txt` (script `scripts/p13_14_regresion.sh`).
import 'package:ceosmos_movil_integral/core/ble/ble_protocolo.dart';
import 'package:ceosmos_movil_integral/core/ble/ecosistema_ble.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_ble.dart';

Future<void> esperar([int ms = 20]) => Future<void>.delayed(Duration(milliseconds: ms));

void main() {
  late PerifericoFalso tablet;
  late TransporteFalso radio;
  late EcosistemaBle ble;

  setUp(() {
    tablet = PerifericoFalso(remoteId: 'AA:BB:CC:00:11:22', id: 'ab0102ff');
    radio = TransporteFalso([tablet]);
    ble = EcosistemaBle(
      transporte: radio,
      pines: AlmacenPinMemoria(),
      esperaBase: const Duration(milliseconds: 5),
    );
  });
  tearDown(() => ble.dispose());

  test('DEF-BLE-01: la TV reiniciada (enlace arriba, sin autorización) vuelve a recibir la sesión', () async {
    var restante = 300;
    ble.estadoSesion = () => EstadoSesionBle(estado: 'running', titulo: 'Órbita', restante: restante--, total: 300);
    expect(await ble.conectar(RolBle.reloj, pin: '123456'), ResultadoConexion.conectado);
    expect(await ble.conectar(RolBle.tv, pin: '123456'), ResultadoConexion.conectado);
    final conexionesAntes = radio.conexiones;

    // La app TV se reinicia: su servidor GATT olvida al central; el Reloj mantiene el enlace.
    tablet.autenticados.remove(RolBle.tv);
    final antes = tablet.recibidos[RolBle.tv]!.length;

    ble.publicarSesion(); // primera escritura: el periférico responde «sin autorización»
    // Espera por condición (máx. 3 s): con el código viejo nunca se reautentica.
    final reloj = Stopwatch()..start();
    while (!tablet.autenticados.contains(RolBle.tv) && reloj.elapsedMilliseconds < 3000) {
      await esperar(10);
    }
    await esperar(40);
    ble.publicarSesion(); // tras reautenticarse, la proyección debe llegar
    await esperar(60);

    final nuevos = tablet.recibidos[RolBle.tv]!.skip(antes).toList();
    expect(tablet.autenticados, contains(RolBle.tv),
        reason: 'CEOSMOS debe volver a responder el reto HMAC con el PIN guardado');
    expect(nuevos.where((m) => m['t'] == 'session'), isNotEmpty,
        reason: 'con el defecto la TV quedaba «Conectado» pero sin recibir ninguna sesión');
    expect(ble[RolBle.tv].estado, EstadoEnlace.conectado);
    expect(ble[RolBle.reloj].estado, EstadoEnlace.conectado, reason: 'el Reloj no se ve afectado');
    expect(radio.conexiones, conexionesAntes,
        reason: 'reutiliza el enlace físico compartido: no abre otra conexión');
  });
}

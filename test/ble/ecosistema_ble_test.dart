// White Box de EcosistemaBle (central BLE de CEOSMOS) con un periférico simulado:
// conexión, PIN, reto, enlace compartido Reloj+TV, datos en ambos sentidos,
// validación, límite de frecuencia, reconexión con espera progresiva y Bluetooth apagado.
import 'dart:async';

import 'package:ceosmos_movil_integral/core/ble/ble_protocolo.dart';
import 'package:ceosmos_movil_integral/core/ble/ble_transporte.dart';
import 'package:ceosmos_movil_integral/core/ble/ecosistema_ble.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_ble.dart';

Future<void> esperar([int ms = 20]) => Future<void>.delayed(Duration(milliseconds: ms));

/// P13-14: espera por CONDICIÓN (máx. [maxMs]) en lugar de un tiempo fijo. Con
/// `flutter test --coverage` en paralelo (CI) la reconexión tardó más de 100 ms y la
/// prueba fallaba de forma intermitente aunque el código fuera correcto.
Future<void> esperarHasta(bool Function() condicion, {int maxMs = 3000}) async {
  final reloj = Stopwatch()..start();
  while (!condicion() && reloj.elapsedMilliseconds < maxMs) {
    await esperar(10);
  }
}

void main() {
  late PerifericoFalso tablet;
  late TransporteFalso radio;
  late AlmacenPinMemoria pines;
  late EcosistemaBle ble;

  setUp(() {
    tablet = PerifericoFalso(remoteId: 'AA:BB:CC:00:11:22', id: 'ab0102ff');
    radio = TransporteFalso([tablet]);
    pines = AlmacenPinMemoria();
    ble = EcosistemaBle(transporte: radio, pines: pines, esperaBase: const Duration(milliseconds: 5));
  });
  tearDown(() => ble.dispose());

  test('primera conexión pide PIN; con PIN correcto conecta y lo guarda', () async {
    expect(await ble.conectar(RolBle.reloj), ResultadoConexion.requierePin);
    expect(ble[RolBle.reloj].idCompanero, 'ab0102ff');
    expect(tablet.conexion!.cerrada, isTrue, reason: 'no deja el enlace abierto sin autenticar');
    expect(await ble.conectar(RolBle.reloj, pin: '123456'), ResultadoConexion.conectado);
    expect(ble[RolBle.reloj].estado, EstadoEnlace.conectado);
    expect(pines.valores['ab0102ff'], '123456');
    expect(tablet.recibidos[RolBle.reloj]!.first, {'t': 'hello', 'name': 'CEOSMOS'});
  });

  test('PIN incorrecto se rechaza, se borra y no queda conectado', () async {
    pines.valores['ab0102ff'] = '000000';
    expect(await ble.conectar(RolBle.reloj), ResultadoConexion.pinIncorrecto);
    expect(pines.valores, isEmpty);
    expect(ble[RolBle.reloj].estado, EstadoEnlace.error);
    expect(ble[RolBle.reloj].error, contains('PIN incorrecto'));
    expect(await ble.conectar(RolBle.reloj, pin: '12'), ResultadoConexion.pinIncorrecto);
  });

  test('sin autenticar, el periférico rechaza escrituras (dispositivo no autorizado)', () async {
    final c = await radio.conectar(tablet.remoteId);
    await c.servicios();
    expect(
      () => c.escribir(RolBle.tv.servicio, RolBle.tv.aDispositivo, [1]),
      throwsA(isA<FalloBle>().having((f) => f.autorizacion, 'autorizacion', isTrue)),
    );
    expect(() => c.suscribir(RolBle.tv.servicio, RolBle.tv.deDispositivo), throwsA(isA<FalloBle>()));
  });

  test('Reloj y TV comparten el mismo enlace físico de la tablet', () async {
    await ble.conectar(RolBle.reloj, pin: '123456');
    expect(await ble.conectar(RolBle.tv, pin: '123456'), ResultadoConexion.conectado);
    expect(radio.conexiones, 1);
    expect(radio.escaneos, 2, reason: 'cada rol lee su id del anuncio, pero el enlace es uno');
    await ble.desconectar(RolBle.reloj);
    expect(tablet.conexion!.cerrada, isFalse, reason: 'la TV sigue usando el enlace');
    await ble.desconectar(RolBle.tv);
    expect(tablet.conexion!.cerrada, isTrue);
  });

  test('datos del reloj → CEOSMOS: lecturas, botón y resumen de sesión', () async {
    final comandos = <String>[];
    ble.alComando = (rol, c) => comandos.add('${rol.etiqueta}:$c');
    await ble.conectar(RolBle.reloj, pin: '123456');
    ble.marcarInicio();
    tablet.enviar(RolBle.reloj, {'t': 'hr', 'hr': 70, 'steps': 10});
    tablet.enviar(RolBle.reloj, {'t': 'hr', 'hr': 80, 'steps': 20});
    tablet.enviar(RolBle.reloj, {'t': 'btn', 'a': 'toggle'});
    tablet.enviar(RolBle.reloj, {'t': 'hr', 'hr': 999}); // fuera de rango
    tablet.enviar(RolBle.reloj, [0x7B, 0x7B]); // basura
    await esperar();
    expect(ble.ultimaLectura!.heartRate, 80);
    expect(ble.muestras, [70, 80]);
    expect(comandos, ['reloj:toggle']);
    expect(ble.descartados, 2);
    final r = ble.resumenSesion()['wearable'] as Map;
    expect(r['transport'], 'BLE');
    expect(r['avgHeartRate'], 75.0);
    expect(r['lastSteps'], 20);
    expect(ble.resumenSesion(deviceId: 'uuid-api')['wearable'], containsPair('deviceId', 'uuid-api'));
  });

  test('CEOSMOS → TV/Reloj: proyección de sesión sin duplicados y notificación', () async {
    var sesion = const EstadoSesionBle(estado: 'running', titulo: 'Órbita', restante: 100, total: 300);
    ble.estadoSesion = () => sesion;
    await ble.conectar(RolBle.tv, pin: '123456');
    await ble.conectar(RolBle.reloj, pin: '123456');
    await esperar();
    ble.publicarSesion();
    ble.publicarSesion(); // igual: no se reenvía
    await esperar();
    final tv = tablet.recibidos[RolBle.tv]!.where((m) => m['t'] == 'session').toList();
    expect(tv, hasLength(1));
    expect(tv.single['title'], 'Órbita');
    sesion = const EstadoSesionBle(estado: 'paused', titulo: 'Órbita', restante: 99, total: 300);
    ble.publicarSesion();
    await esperar();
    expect(tablet.recibidos[RolBle.tv]!.last['state'], 'paused');
    expect(await ble.notificarReloj('  Sesión terminada  '), isTrue);
    expect(await ble.notificarReloj('   '), isFalse);
    expect(tablet.recibidos[RolBle.reloj]!.last, {'t': 'notif', 'msg': 'Sesión terminada'});
  });

  test('comandos de la TV y límite de frecuencia (anti-inundación)', () async {
    final comandos = <String>[];
    ble.alComando = (_, c) => comandos.add(c);
    await ble.conectar(RolBle.tv, pin: '123456');
    for (var i = 0; i < 50; i++) {
      tablet.enviar(RolBle.tv, {'t': 'cmd', 'c': 'next'});
    }
    await esperar();
    expect(comandos.length, ble.maxMensajesPorSegundo);
    expect(ble.descartados, 30);
  });

  test('pérdida del enlace → reconexión automática con el PIN guardado', () async {
    await ble.conectar(RolBle.reloj, pin: '123456');
    tablet.conexion!.cortar();
    await esperar(5);
    expect(ble[RolBle.reloj].estado, isIn([EstadoEnlace.reconectando, EstadoEnlace.conectado]));
    await esperarHasta(() => ble[RolBle.reloj].estado == EstadoEnlace.conectado);
    expect(ble[RolBle.reloj].estado, EstadoEnlace.conectado);
    expect(radio.conexiones, 2);
  });

  test('el periférico desaparece → agota los reintentos y queda en error', () async {
    await ble.conectar(RolBle.reloj, pin: '123456');
    tablet.anunciando = false;
    tablet.conexion!.cortar();
    await esperar(1500);
    expect(ble[RolBle.reloj].estado, EstadoEnlace.error);
    expect(ble[RolBle.reloj].error, contains('No se pudo reconectar'));
  });

  test('desconexión manual no reconecta', () async {
    await ble.conectar(RolBle.reloj, pin: '123456');
    await ble.desconectar(RolBle.reloj);
    await esperar(100);
    expect(ble[RolBle.reloj].estado, EstadoEnlace.desconectado);
    expect(radio.conexiones, 1);
    expect(tablet.recibidos[RolBle.reloj]!.last, {'t': 'bye'});
  });

  test('Bluetooth apagado: no conecta; al encender reconecta solo', () async {
    await ble.conectar(RolBle.tv, pin: '123456');
    radio.cambiarAdaptador(AdaptadorBle.apagado);
    await esperar();
    expect(ble[RolBle.tv].estado, EstadoEnlace.reconectando);
    expect(ble.adaptador, AdaptadorBle.apagado);
    expect(await ble.conectar(RolBle.reloj), ResultadoConexion.bluetoothApagado);
    expect(ble[RolBle.reloj].error, contains('Enciende el Bluetooth'));
    await esperar(50);
    expect(radio.conexiones, 1, reason: 'no gasta intentos sin Bluetooth');
    await ble.encenderBluetooth();
    await esperarHasta(() => ble[RolBle.tv].estado == EstadoEnlace.conectado);
    expect(ble[RolBle.tv].estado, EstadoEnlace.conectado);
  });

  test('permiso denegado y periférico ausente', () async {
    radio.permisoDenegado = true;
    expect(await ble.conectar(RolBle.reloj), ResultadoConexion.sinPermiso);
    expect(ble[RolBle.reloj].error, contains('Permiso de Bluetooth denegado'));
    radio.permisoDenegado = false;
    tablet.anunciando = false;
    expect(await ble.conectar(RolBle.tv), ResultadoConexion.noEncontrado);
    radio.estado = AdaptadorBle.sinPermiso;
    expect(await ble.conectar(RolBle.tv), ResultadoConexion.sinPermiso);
  });

  test('periférico solo con servicio Reloj no sirve como TV; olvidar borra el PIN', () async {
    final soloReloj = PerifericoFalso(remoteId: 'R', id: '00000001', roles: {RolBle.reloj});
    final b2 = EcosistemaBle(transporte: TransporteFalso([soloReloj]), pines: pines);
    expect(await b2.conectar(RolBle.tv), ResultadoConexion.noEncontrado);
    expect(await b2.conectar(RolBle.reloj, pin: '123456'), ResultadoConexion.conectado);
    expect(pines.valores['00000001'], '123456');
    await b2.olvidar(RolBle.reloj);
    expect(pines.valores.containsKey('00000001'), isFalse);
    b2.dispose();
  });

  test('3 PIN erróneos: el periférico corta el enlace', () async {
    for (var i = 0; i < 3; i++) {
      await ble.conectar(RolBle.reloj, pin: '99999$i');
    }
    expect(tablet.fallos, 3);
    expect(tablet.conexion!.cerrada, isTrue);
  });

  test('conexión concurrente del mismo rol se ignora', () async {
    final a = ble.conectar(RolBle.reloj, pin: '123456');
    final b = ble.conectar(RolBle.reloj, pin: '123456');
    expect(await b, ResultadoConexion.fallo);
    expect(await a, ResultadoConexion.conectado);
    unawaited(Future<void>.value());
  });

  test('errores GATT al conectar o autenticar → fallo controlado sin enlace abierto', () async {
    radio.falloAlConectar = true;
    expect(await ble.conectar(RolBle.reloj, pin: '123456'), ResultadoConexion.fallo);
    expect(ble[RolBle.reloj].error, contains('timeout'));
    radio.falloAlConectar = false;
    tablet.authRota = true;
    expect(await ble.conectar(RolBle.reloj, pin: '123456'), ResultadoConexion.fallo);
    expect(tablet.conexion!.cerrada, isTrue);
    expect(pines.valores, isEmpty, reason: 'un error de radio no guarda ni borra PIN');
  });

  test('saludo del periférico, mensaje imposible de codificar y encendido rechazado', () async {
    await ble.conectar(RolBle.tv, pin: '123456');
    tablet.enviar(RolBle.tv, {'t': 'hello', 'name': 'Tablet sala'});
    await esperar();
    expect(ble[RolBle.tv].nombreRemoto, 'Tablet sala');
    expect(await ble.enviar(RolBle.tv, {'t': 'x', 'data': 'z' * 400}), isFalse);
    expect(await ble.enviar(RolBle.reloj, {'t': 'notif', 'msg': 'a'}), isFalse, reason: 'rol sin conectar');
    radio
      ..falloAlEncender = true
      ..estado = AdaptadorBle.apagado;
    await ble.encenderBluetooth(); // no lanza: se registra y la UI sigue mostrando «apagado»
    expect(radio.estado, AdaptadorBle.apagado);
  });

  test('al reconectar con un PIN que cambió en el periférico, deja de reintentar', () async {
    await ble.conectar(RolBle.reloj, pin: '123456');
    tablet.pin = '777777'; // «Nuevo PIN» en el reloj revoca el acceso
    tablet.conexion!.cortar();
    await esperarHasta(() => ble[RolBle.reloj].estado == EstadoEnlace.error);
    expect(ble[RolBle.reloj].estado, EstadoEnlace.error);
    expect(pines.valores, isEmpty);
    expect(radio.conexiones, 2, reason: 'un solo intento: con PIN rechazado no se insiste');
  });

  test('desconectar durante la reconexión la cancela', () async {
    await ble.conectar(RolBle.reloj, pin: '123456');
    tablet.anunciando = false;
    tablet.conexion!.cortar();
    await esperar(2);
    await ble.desconectar(RolBle.reloj);
    tablet.anunciando = true;
    await esperar(300);
    expect(ble[RolBle.reloj].estado, EstadoEnlace.desconectado);
    expect(radio.conexiones, 1);
  });

  test('el periférico pierde la autorización sin caer el enlace → se reautentica solo', () async {
    var n = 0;
    ble.estadoSesion = () => EstadoSesionBle(estado: 'running', restante: 100 - n++, total: 300);
    await ble.conectar(RolBle.tv, pin: '123456');
    tablet.autenticados.clear(); // la app TV se reinició; el enlace sigue arriba
    ble.publicarSesion();
    await esperarHasta(() => tablet.autenticados.contains(RolBle.tv) && ble[RolBle.tv].estado == EstadoEnlace.conectado);
    expect(ble[RolBle.tv].estado, EstadoEnlace.conectado);
    expect(tablet.autenticados, contains(RolBle.tv));
    ble.publicarSesion();
    await esperar();
    expect(tablet.recibidos[RolBle.tv]!.last['t'], 'session');
  });

  test('Bluetooth vuelve: Reloj y TV reconectan aunque escaneen a la vez (escaneo en serie)', () async {
    await ble.conectar(RolBle.reloj, pin: '123456');
    await ble.conectar(RolBle.tv, pin: '123456');
    radio.cambiarAdaptador(AdaptadorBle.apagado);
    await esperar();
    radio.cambiarAdaptador(AdaptadorBle.encendido);
    await esperarHasta(() =>
        ble[RolBle.reloj].estado == EstadoEnlace.conectado && ble[RolBle.tv].estado == EstadoEnlace.conectado);
    expect(ble[RolBle.reloj].estado, EstadoEnlace.conectado);
    expect(ble[RolBle.tv].estado, EstadoEnlace.conectado);
  });
}

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../wearable.dart';
import 'ble_protocolo.dart';
import 'ble_transporte.dart';

enum EstadoEnlace { desconectado, buscando, conectando, autenticando, conectado, reconectando, error }

enum ResultadoConexion { conectado, requierePin, pinIncorrecto, noEncontrado, bluetoothApagado, sinPermiso, fallo }

/// Estado visible de un rol (Reloj o TV).
class EnlaceBle {
  EnlaceBle(this.rol);
  final RolBle rol;
  EstadoEnlace estado = EstadoEnlace.desconectado;
  String? error;

  /// Id estable del compañero (4 bytes del anuncio, en hexadecimal).
  String? idCompanero;
  String? remoteId;
  String? nombreRemoto;
  DateTime? ultimoDato;
  int reintento = 0;

  bool get activo => estado == EstadoEnlace.conectado;
}

/// PIN de cada compañero, guardado en el almacenamiento seguro de CEOSMOS.
abstract interface class AlmacenPinBle {
  Future<String?> leer(String idCompanero);
  Future<void> guardar(String idCompanero, String pin);
  Future<void> borrar(String idCompanero);
}

class AlmacenPinSeguro implements AlmacenPinBle {
  static const _s = FlutterSecureStorage(
    aOptions: AndroidOptions(storageNamespace: 'ceosmos_secure_storage'),
  );
  @override
  Future<String?> leer(String id) => _s.read(key: 'ble_pin_$id');
  @override
  Future<void> guardar(String id, String pin) => _s.write(key: 'ble_pin_$id', value: pin);
  @override
  Future<void> borrar(String id) => _s.delete(key: 'ble_pin_$id');
}

class AlmacenPinMemoria implements AlmacenPinBle {
  final valores = <String, String>{};
  @override
  Future<String?> leer(String id) async => valores[id];
  @override
  Future<void> guardar(String id, String pin) async => valores[id] = pin;
  @override
  Future<void> borrar(String id) async => valores.remove(id);
}

class _Enlace {
  _Enlace(this.conexion, this.servicios);
  final ConexionBle conexion;
  final Set<String> servicios;
  final roles = <RolBle>{};
  final subs = <RolBle, StreamSubscription<List<int>>>{};
}

/// Lado CENTRAL de CEOSMOS: busca, conecta, autentica e intercambia datos con
/// el Reloj y la TV compañeros; reconecta con espera progresiva si se pierde
/// el enlace y espera a que vuelva el Bluetooth si se apaga.
class EcosistemaBle extends ChangeNotifier {
  EcosistemaBle({
    required this.transporte,
    AlmacenPinBle? pines,
    this.esperaBase = const Duration(seconds: 1),
    this.maxReintentos = 6,
    this.duracionEscaneo = const Duration(seconds: 8),
    this.maxMensajesPorSegundo = 20,
  }) : pines = pines ?? AlmacenPinMemoria() {
    adaptador = transporte.adaptadorAhora;
    _subAdaptador = transporte.adaptador.listen(_alCambiarAdaptador);
  }

  final BleTransporte transporte;
  final AlmacenPinBle pines;
  final Duration esperaBase, duracionEscaneo;
  final int maxReintentos, maxMensajesPorSegundo;

  late AdaptadorBle adaptador;
  late final StreamSubscription<AdaptadorBle> _subAdaptador;
  final enlaces = {for (final r in RolBle.values) r: EnlaceBle(r)};
  final _activos = <String, _Enlace>{}; // por remoteId
  final _manual = <RolBle>{}; // desconexión pedida por el usuario
  final _ocupado = <RolBle>{};
  final _cola = <RolBle, Future<void>>{};
  final _ultimoEnviado = <RolBle, String>{};
  final _ventana = <RolBle, List<int>>{};
  bool _disposed = false;
  Future<void> _candado = Future.value();

  /// Ejecuta [f] cuando termine la operación de radio anterior (sin bloquear la cola si falla).
  Future<T> _enSerie<T>(Future<T> Function() f) {
    final r = _candado.then((_) => f());
    _candado = r.then<void>((_) {}, onError: (Object _) {});
    return r;
  }

  /// Datos del reloj.
  WearableLectura? ultimaLectura;
  final List<int> _muestras = [];
  List<int> get muestras => List.unmodifiable(_muestras);

  /// Último comando recibido (para mostrarlo en pantalla).
  String? ultimoComando;

  /// Mensajes descartados por inválidos o por exceso de frecuencia.
  int descartados = 0;

  /// Lo asigna [AppState]: pausar, terminar o cambiar de ambiente.
  void Function(RolBle rol, String comando)? alComando;

  /// Lo asigna [AppState]: estado de la sesión que se proyecta.
  EstadoSesionBle Function()? estadoSesion;

  EnlaceBle operator [](RolBle r) => enlaces[r]!;

  void _cambio() {
    if (!_disposed) notifyListeners();
  }

  void _alCambiarAdaptador(AdaptadorBle a) {
    adaptador = a;
    if (a != AdaptadorBle.encendido) {
      for (final e in enlaces.values) {
        if (e.estado == EstadoEnlace.conectado) {
          e.estado = EstadoEnlace.reconectando;
          e.error = 'Bluetooth apagado: se reconectará al encenderlo.';
        }
      }
    }
    _cambio();
  }

  Future<void> encenderBluetooth() async {
    try {
      await transporte.encender();
    } on Exception catch (e) {
      debugPrint('BLE: no se encendió el adaptador (${e.runtimeType})');
    }
  }

  // ---------------------------------------------------------------------------
  // Conexión
  // ---------------------------------------------------------------------------

  Future<ResultadoConexion> conectar(RolBle rol, {String? pin, String? idCompanero}) async {
    if (_ocupado.contains(rol)) return ResultadoConexion.fallo;
    _ocupado.add(rol);
    _manual.remove(rol);
    try {
      final r = await _intentar(rol, pin: pin, idCompanero: idCompanero);
      if (r != ResultadoConexion.conectado && r != ResultadoConexion.requierePin) {
        this[rol].estado = EstadoEnlace.error;
      } else if (r == ResultadoConexion.requierePin) {
        this[rol].estado = EstadoEnlace.desconectado;
      }
      _cambio();
      return r;
    } finally {
      _ocupado.remove(rol);
    }
  }

  Future<ResultadoConexion> _intentar(RolBle rol, {String? pin, String? idCompanero}) async {
    final e = this[rol];
    e.error = null;
    if (pin != null && !pinValido(pin)) {
      e.error = 'El PIN tiene 6 dígitos.';
      return ResultadoConexion.pinIncorrecto;
    }
    if (transporte.adaptadorAhora != AdaptadorBle.encendido) {
      e.error = transporte.adaptadorAhora == AdaptadorBle.sinPermiso
          ? 'CEOSMOS no tiene permiso de Bluetooth.'
          : 'Enciende el Bluetooth para conectar.';
      return transporte.adaptadorAhora == AdaptadorBle.sinPermiso
          ? ResultadoConexion.sinPermiso
          : ResultadoConexion.bluetoothApagado;
    }
    _Enlace? enlace;
    String? id = idCompanero ?? e.idCompanero;
    try {
      // 1. Siempre se escanea el servicio del rol: el anuncio trae el id del compañero
      //    (Reloj y TV pueden ser apps distintas en la misma tablet, con PIN e id propios).
      // Android permite un solo escaneo por app y detenerlo corta el de otro rol:
      // escaneo y conexión van en serie (Reloj y TV reconectan a la vez al volver el BT).
      final hallado = await _enSerie(() async {
        e.estado = EstadoEnlace.buscando;
        _cambio();
        HallazgoBle? elegido;
        await for (final h in transporte.escanear(rol.servicio, duracionEscaneo)) {
          final hid = leerIdCompanero(h.datosFabricante, rol);
          if (id == null || hid == id) {
            elegido = h;
            break;
          }
        }
        await transporte.detenerEscaneo();
        if (elegido == null) return null;
        final idHallado = leerIdCompanero(elegido.datosFabricante, rol) ?? id;
        var en = _activos[elegido.remoteId] ??
            _activos.values.where((a) => a.servicios.contains(rol.servicio)).firstOrNull;
        if (en == null) {
          e.estado = EstadoEnlace.conectando;
          _cambio();
          final c = await transporte.conectar(elegido.remoteId);
          final servicios = await c.servicios();
          en = _Enlace(c, servicios);
          _activos[c.remoteId] = en;
          unawaited(c.perdida.then((_) => _alPerder(c.remoteId)));
        }
        return (en, idHallado);
      });
      if (hallado == null) {
        e.error = 'No se encontró el ${rol.nombre} CEOSMOS. Ábrelo en la tablet y revisa que anuncie.';
        return ResultadoConexion.noEncontrado;
      }
      enlace = hallado.$1;
      id = hallado.$2;
      if (!enlace.servicios.contains(rol.servicio)) {
        e.error = 'El dispositivo no expone el servicio de ${rol.nombre}.';
        await _soltar(enlace, rol);
        return ResultadoConexion.fallo;
      }
      e.idCompanero = id;
      e.remoteId = enlace.conexion.remoteId;
      final clave = pin ?? (id == null ? null : await pines.leer(id));
      if (clave == null) {
        await _soltar(enlace, rol);
        return ResultadoConexion.requierePin;
      }

      // 2. Autenticación por reto (el PIN nunca viaja por el aire).
      e.estado = EstadoEnlace.autenticando;
      _cambio();
      final reto = await enlace.conexion.leer(rol.servicio, rol.auth);
      try {
        await enlace.conexion.escribir(rol.servicio, rol.auth, respuestaReto(clave, reto, rol));
      } on FalloBle catch (f) {
        if (!f.autorizacion) rethrow;
        if (id != null) await pines.borrar(id);
        e.error = 'PIN incorrecto. Revisa el PIN que muestra el ${rol.nombre}.';
        await _soltar(enlace, rol);
        return ResultadoConexion.pinIncorrecto;
      }
      if (id != null) await pines.guardar(id, clave);

      // 3. Datos del periférico.
      final flujo = await enlace.conexion.suscribir(rol.servicio, rol.deDispositivo);
      unawaited(enlace.subs[rol]?.cancel());
      enlace.subs[rol] = flujo.listen((b) => _alRecibir(rol, b));
      enlace.roles.add(rol);
      e
        ..estado = EstadoEnlace.conectado
        ..reintento = 0
        ..error = null;
      _ultimoEnviado.remove(rol);
      _cambio();
      await enviar(rol, {'t': 'hello', 'name': 'CEOSMOS'});
      publicarSesion();
      return ResultadoConexion.conectado;
    } on PermisoBleDenegado {
      e.error = 'Permiso de Bluetooth denegado. Actívalo en Ajustes › Apps › CEOSMOS › Permisos.';
      if (enlace != null) await _soltar(enlace, rol);
      return ResultadoConexion.sinPermiso;
    } on FalloBle catch (f) {
      e.error = 'No se pudo conectar con el ${rol.nombre}: ${f.mensaje}';
      if (enlace != null) await _soltar(enlace, rol);
      return ResultadoConexion.fallo;
    } on ArgumentError {
      e.error = 'El ${rol.nombre} respondió un reto inválido.';
      if (enlace != null) await _soltar(enlace, rol);
      return ResultadoConexion.fallo;
    }
  }

  /// Quita el rol del enlace y lo cierra si ya nadie lo usa.
  Future<void> _soltar(_Enlace enlace, RolBle rol) async {
    enlace.roles.remove(rol);
    // No se espera la cancelación: algunos flujos de la plataforma no la confirman nunca.
    unawaited(enlace.subs.remove(rol)?.cancel());
    if (enlace.roles.isEmpty) {
      _activos.remove(enlace.conexion.remoteId);
      await enlace.conexion.desconectar();
    }
  }

  Future<void> desconectar(RolBle rol) async {
    _manual.add(rol);
    final e = this[rol];
    final enlace = _activos.values.where((a) => a.roles.contains(rol)).firstOrNull;
    if (enlace != null) {
      await enviar(rol, {'t': 'bye'});
      await _soltar(enlace, rol);
    }
    e
      ..estado = EstadoEnlace.desconectado
      ..error = null
      ..reintento = 0;
    if (rol == RolBle.reloj) ultimaLectura = null;
    _cambio();
  }

  /// Olvida el PIN guardado (la próxima conexión lo vuelve a pedir).
  Future<void> olvidar(RolBle rol) async {
    final id = this[rol].idCompanero;
    await desconectar(rol);
    if (id != null) await pines.borrar(id);
    this[rol].idCompanero = null;
    _cambio();
  }

  /// El periférico reinició su servidor GATT sin que se cayera el enlace físico
  /// (p. ej. la app TV se cerró y se abrió mientras el Reloj mantenía la conexión):
  /// rechaza las escrituras por falta de autorización. Se vuelve a autenticar ese rol.
  void _autorizacionPerdida(RolBle rol, _Enlace enlace) {
    final e = this[rol];
    if (_disposed || _manual.contains(rol) || e.estado != EstadoEnlace.conectado) return;
    e.error = 'El ${rol.nombre} se reinició. Autenticando de nuevo…';
    unawaited(_soltar(enlace, rol).then((_) => _reconectar(rol)));
  }

  void _alPerder(String remoteId) {
    final enlace = _activos.remove(remoteId);
    if (enlace == null || _disposed) return;
    for (final s in enlace.subs.values) {
      unawaited(s.cancel());
    }
    for (final rol in enlace.roles.toList()) {
      if (_manual.contains(rol)) continue;
      unawaited(_reconectar(rol));
    }
  }

  Future<void> _reconectar(RolBle rol) async {
    final e = this[rol];
    e.estado = EstadoEnlace.reconectando;
    e.error ??= 'Se perdió el enlace con el ${rol.nombre}. Reconectando…';
    _cambio();
    for (var i = 0; i < maxReintentos; i++) {
      // Sin Bluetooth no se gastan intentos: se espera a que vuelva.
      while (adaptador != AdaptadorBle.encendido && !_disposed && !_manual.contains(rol)) {
        await transporte.adaptador.firstWhere((a) => a == AdaptadorBle.encendido).timeout(
              const Duration(minutes: 10),
              onTimeout: () => AdaptadorBle.apagado,
            );
        adaptador = transporte.adaptadorAhora;
        if (adaptador != AdaptadorBle.encendido) break;
      }
      if (_disposed || _manual.contains(rol)) return;
      final espera = esperaBase * min(pow(2, i).toInt(), 30);
      e.reintento = i + 1;
      _cambio();
      await Future<void>.delayed(espera);
      if (_disposed || _manual.contains(rol)) return;
      if (_ocupado.contains(rol)) continue;
      _ocupado.add(rol);
      final r = await _intentar(rol, idCompanero: e.idCompanero).whenComplete(() => _ocupado.remove(rol));
      if (r == ResultadoConexion.conectado) return;
      if (r == ResultadoConexion.pinIncorrecto || r == ResultadoConexion.requierePin) break;
      e.estado = EstadoEnlace.reconectando;
      _cambio();
    }
    if (_disposed || _manual.contains(rol)) return;
    e
      ..estado = EstadoEnlace.error
      ..error = 'No se pudo reconectar con el ${rol.nombre}. Pulsa «Conectar» para intentarlo de nuevo.';
    _cambio();
  }

  // ---------------------------------------------------------------------------
  // Datos
  // ---------------------------------------------------------------------------

  void _alRecibir(RolBle rol, List<int> bytes) {
    final ahora = DateTime.now().millisecondsSinceEpoch;
    final ventana = _ventana.putIfAbsent(rol, () => [])..removeWhere((t) => ahora - t > 1000);
    if (ventana.length >= maxMensajesPorSegundo) {
      descartados++;
      return;
    }
    ventana.add(ahora);
    final m = decodificar(bytes, rol);
    if (m == null) {
      descartados++;
      return;
    }
    final e = this[rol]..ultimoDato = DateTime.now();
    switch (m) {
      case LecturaReloj(:final hr, :final pasos):
        ultimaLectura = WearableLectura(heartRate: hr, steps: pasos, at: DateTime.now());
        _muestras.add(hr);
        if (_muestras.length > 3600) _muestras.removeAt(0);
      case ComandoRemoto(:final comando):
        ultimoComando = '${rol.nombre}: $comando';
        alComando?.call(rol, comando);
      case SaludoRemoto(:final nombre):
        e.nombreRemoto = nombre;
    }
    _cambio();
  }

  /// Envía un mensaje al rol (en orden: una operación GATT a la vez por rol).
  Future<bool> enviar(RolBle rol, Map<String, Object?> mensaje) {
    final enlace = _activos.values.where((a) => a.roles.contains(rol) || a.servicios.contains(rol.servicio)).firstOrNull;
    if (enlace == null || (this[rol].estado != EstadoEnlace.conectado && mensaje['t'] != 'bye')) {
      return Future.value(false);
    }
    final List<int> bytes;
    try {
      bytes = codificar(mensaje);
    } on ArgumentError {
      return Future.value(false);
    }
    final ok = Completer<bool>();
    // La cola nunca queda en error: un fallo no bloquea los envíos siguientes.
    _cola[rol] = (_cola[rol] ?? Future.value()).then((_) async {
      try {
        await enlace.conexion.escribir(rol.servicio, rol.aDispositivo, bytes);
        ok.complete(true);
      } on FalloBle catch (f) {
        ok.complete(false);
        if (f.autorizacion) _autorizacionPerdida(rol, enlace);
      } catch (_) {
        ok.complete(false);
      }
    });
    return ok.future;
  }

  Future<bool> notificarReloj(String texto) {
    final t = texto.trim();
    if (t.isEmpty) return Future.value(false);
    return enviar(RolBle.reloj, {'t': 'notif', 'msg': t.length > 120 ? t.substring(0, 120) : t});
  }

  /// Proyecta la sesión en los roles conectados (solo si cambió).
  void publicarSesion() {
    final s = estadoSesion?.call() ?? EstadoSesionBle.inactivo;
    for (final rol in RolBle.values) {
      if (!this[rol].activo) continue;
      final m = s.aMensaje(hr: rol == RolBle.tv ? ultimaLectura?.heartRate : null);
      final firma = jsonEncode(m);
      if (_ultimoEnviado[rol] == firma) continue;
      _ultimoEnviado[rol] = firma;
      unawaited(enviar(rol, m));
    }
  }

  void marcarInicio() => _muestras.clear();

  /// Resumen del reloj BLE para el historial (JSONB `metadata`).
  Map<String, Object> resumenSesion({String? deviceId}) {
    final m = _muestras;
    final id = deviceId ?? this[RolBle.reloj].idCompanero;
    if (m.isEmpty || id == null) return const {};
    final promedio = m.reduce((a, b) => a + b) / m.length;
    return {
      'wearable': {
        'deviceId': id,
        'transport': 'BLE',
        'samples': m.length,
        'avgHeartRate': double.parse(promedio.toStringAsFixed(1)),
        'minHeartRate': m.reduce(min),
        'maxHeartRate': m.reduce(max),
        if (ultimaLectura?.steps != null) 'lastSteps': ultimaLectura!.steps!,
      },
    };
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_subAdaptador.cancel());
    for (final a in _activos.values.toList()) {
      for (final s in a.subs.values) {
        unawaited(s.cancel());
      }
      unawaited(a.conexion.desconectar());
    }
    _activos.clear();
    super.dispose();
  }
}

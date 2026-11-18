// Transporte BLE falso: simula la tablet con las apps compañeras (servidor GATT
// con los servicios Reloj y TV, reto + HMAC, bloqueo tras 3 PIN erróneos).
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:ceosmos_movil_integral/core/ble/ble_protocolo.dart';
import 'package:ceosmos_movil_integral/core/ble/ble_transporte.dart';
import 'package:collection/collection.dart';

class PerifericoFalso {
  PerifericoFalso({
    required this.remoteId,
    required this.id,
    this.pin = '123456',
    Set<RolBle>? roles,
  }) : roles = roles ?? {RolBle.reloj, RolBle.tv};

  final String remoteId;
  final String id; // 8 hex
  String pin;
  final Set<RolBle> roles;
  final recibidos = <RolBle, List<Map<String, dynamic>>>{};
  final autenticados = <RolBle>{};
  final _retos = <RolBle, List<int>>{};
  final notificadores = <RolBle, StreamController<List<int>>>{};
  int fallos = 0;
  bool anunciando = true;
  ConexionFalsa? conexion;

  List<int> manufacturer(RolBle r) => [
        r.codigo,
        for (var i = 0; i < 8; i += 2) int.parse(id.substring(i, i + 2), radix: 16),
      ];

  /// El periférico envía un mensaje (notificación).
  void enviar(RolBle rol, Object mensaje) {
    final bytes = mensaje is List<int> ? mensaje : utf8.encode(jsonEncode(mensaje));
    notificadores[rol]?.add(bytes);
  }
}

class TransporteFalso implements BleTransporte {
  TransporteFalso(this.perifericos);
  final List<PerifericoFalso> perifericos;
  final _adaptador = StreamController<AdaptadorBle>.broadcast();
  AdaptadorBle estado = AdaptadorBle.encendido;
  bool permisoDenegado = false;
  int escaneos = 0, conexiones = 0;

  void cambiarAdaptador(AdaptadorBle a) {
    estado = a;
    _adaptador.add(a);
    if (a != AdaptadorBle.encendido) {
      for (final p in perifericos) {
        p.conexion?.cortar();
      }
    }
  }

  @override
  AdaptadorBle get adaptadorAhora => estado;
  @override
  Stream<AdaptadorBle> get adaptador => _adaptador.stream;
  @override
  Future<void> encender() async => cambiarAdaptador(AdaptadorBle.encendido);

  @override
  Stream<HallazgoBle> escanear(String servicio, Duration duracion) async* {
    if (permisoDenegado) throw const PermisoBleDenegado();
    escaneos++;
    for (final p in perifericos) {
      final rol = RolBle.values.firstWhereOrNull((r) => r.servicio == servicio);
      if (rol != null && p.anunciando && p.roles.contains(rol)) {
        yield HallazgoBle(remoteId: p.remoteId, rssi: -50, datosFabricante: {fabricanteCeosmos: p.manufacturer(rol)});
      }
    }
  }

  @override
  Future<void> detenerEscaneo() async {}

  @override
  Future<ConexionBle> conectar(String remoteId) async {
    final p = perifericos.firstWhere((p) => p.remoteId == remoteId);
    if (!p.anunciando) throw const FalloBle('timeout');
    conexiones++;
    p.autenticados.clear();
    final c = ConexionFalsa(p);
    p.conexion = c;
    return c;
  }
}

class ConexionFalsa implements ConexionBle {
  ConexionFalsa(this.p);
  final PerifericoFalso p;
  final _perdida = Completer<void>();
  bool cerrada = false;

  void cortar() {
    cerrada = true;
    p.autenticados.clear();
    if (!_perdida.isCompleted) _perdida.complete();
  }

  RolBle _rol(String servicio) => RolBle.values.firstWhere((r) => r.servicio == servicio);

  @override
  String get remoteId => p.remoteId;
  @override
  Future<void> get perdida => _perdida.future;

  @override
  Future<Set<String>> servicios() async => {for (final r in p.roles) r.servicio};

  @override
  Future<List<int>> leer(String servicio, String caracteristica) async {
    if (cerrada) throw const FalloBle('desconectado');
    final rol = _rol(servicio);
    if (caracteristica != rol.auth) throw const FalloBle('no legible');
    final r = Random();
    return p._retos[rol] = List.generate(16, (_) => r.nextInt(256));
  }

  @override
  Future<void> escribir(String servicio, String caracteristica, List<int> datos) async {
    if (cerrada) throw const FalloBle('desconectado');
    final rol = _rol(servicio);
    if (caracteristica == rol.auth) {
      final reto = p._retos.remove(rol);
      if (reto != null && const ListEquality<int>().equals(datos, respuestaReto(p.pin, reto, rol))) {
        p.autenticados.add(rol);
        return;
      }
      if (++p.fallos >= 3) cortar();
      throw const FalloBle('GATT_INSUFFICIENT_AUTHORIZATION', autorizacion: true);
    }
    if (!p.autenticados.contains(rol)) {
      throw const FalloBle('GATT_INSUFFICIENT_AUTHORIZATION', autorizacion: true);
    }
    (p.recibidos[rol] ??= []).add(jsonDecode(utf8.decode(datos)) as Map<String, dynamic>);
  }

  @override
  Future<Stream<List<int>>> suscribir(String servicio, String caracteristica) async {
    final rol = _rol(servicio);
    if (!p.autenticados.contains(rol)) {
      throw const FalloBle('GATT_INSUFFICIENT_AUTHORIZATION', autorizacion: true);
    }
    final c = p.notificadores[rol] = StreamController<List<int>>.broadcast();
    return c.stream;
  }

  @override
  Future<void> desconectar() async => cortar();
}

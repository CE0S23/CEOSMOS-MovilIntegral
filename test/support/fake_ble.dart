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
  bool authRota = false; // la escritura del reto falla por otra causa (no PIN)
  bool escrituraRota = false; // servidor GATT reiniciado: las escrituras fallan sin error de autorización
  bool silencioso = false; // las escrituras «pasan» pero el periférico no responde
  bool anunciando = true;
  ConexionFalsa? conexion;

  /// 1.4.0: las próximas N escrituras de datos fallan una vez (radio ocupada).
  int fallosTransitorios = 0;

  /// Operaciones GATT simultáneas en el enlace (Android admite una sola).
  int opsEnVuelo = 0, maxOpsEnVuelo = 0;

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
  bool falloAlConectar = false, falloAlEncender = false;
  /// Como Web Bluetooth: los hallazgos no traen datos de fabricante.
  bool sinDatosFabricante = false;
  int escaneos = 0, conexiones = 0;
  int _generacion = 0;

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
  Future<void> encender() async {
    if (falloAlEncender) throw const FalloBle('El usuario rechazó encender el Bluetooth');
    cambiarAdaptador(AdaptadorBle.encendido);
  }

  @override
  Stream<HallazgoBle> escanear(String servicio, Duration duracion) async* {
    if (permisoDenegado) throw const PermisoBleDenegado();
    escaneos++;
    // Como Android/flutter_blue_plus: un solo escaneo a la vez por app; empezar
    // otro detiene el anterior (que termina sin resultados).
    final g = ++_generacion;
    await Future<void>.delayed(const Duration(milliseconds: 3));
    for (final p in perifericos) {
      if (g != _generacion) return;
      final rol = RolBle.values.firstWhereOrNull((r) => r.servicio == servicio);
      if (rol != null && p.anunciando && p.roles.contains(rol)) {
        yield HallazgoBle(remoteId: p.remoteId, rssi: -50, datosFabricante: sinDatosFabricante ? const {} : {fabricanteCeosmos: p.manufacturer(rol)});
      }
    }
  }

  @override
  Future<void> detenerEscaneo() async => _generacion++; // detiene cualquier escaneo en curso

  @override
  Future<ConexionBle> conectar(String remoteId) async {
    final p = perifericos.firstWhere((p) => p.remoteId == remoteId);
    if (!p.anunciando || falloAlConectar) throw const FalloBle('timeout');
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

  /// Marca una operación GATT en vuelo durante [ms] para detectar solapamientos.
  Future<void> _ocupar([int ms = 0]) async {
    p.opsEnVuelo++;
    if (p.opsEnVuelo > p.maxOpsEnVuelo) p.maxOpsEnVuelo = p.opsEnVuelo;
    await Future<void>.delayed(Duration(milliseconds: ms));
    p.opsEnVuelo--;
  }

  @override
  Future<List<int>> leer(String servicio, String caracteristica) async {
    await _ocupar();
    if (cerrada) throw const FalloBle('desconectado');
    final rol = _rol(servicio);
    if (caracteristica != rol.auth) throw const FalloBle('no legible');
    final r = Random();
    return p._retos[rol] = List.generate(16, (_) => r.nextInt(256));
  }

  @override
  Future<void> escribir(String servicio, String caracteristica, List<int> datos) async {
    await _ocupar();
    if (cerrada) throw const FalloBle('desconectado');
    final rol = _rol(servicio);
    if (caracteristica == rol.auth) {
      if (p.authRota) throw const FalloBle('GATT_ERROR 133');
      final reto = p._retos.remove(rol);
      if (reto != null && const ListEquality<int>().equals(datos, respuestaReto(p.pin, reto, rol))) {
        p.autenticados.add(rol);
        p.escrituraRota = false; // nueva autenticación = servicios redescubiertos
        p.silencioso = false;
        return;
      }
      if (++p.fallos >= 3) cortar();
      throw const FalloBle('GATT_INSUFFICIENT_AUTHORIZATION', autorizacion: true);
    }
    if (p.escrituraRota) throw const FalloBle('GATT_ERROR 133');
    if (p.fallosTransitorios > 0) {
      p.fallosTransitorios--;
      throw const FalloBle('GATT_BUSY');
    }
    if (p.silencioso) return;
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

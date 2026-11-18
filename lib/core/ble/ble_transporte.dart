// Abstracción del radio BLE. La implementación real usa flutter_blue_plus
// (`ble_transporte_fbp.dart`); las pruebas usan un transporte falso que simula
// el periférico, así la lógica de [EcosistemaBle] se prueba sin hardware.

enum AdaptadorBle { desconocido, apagado, encendido, noDisponible, sinPermiso }

/// Un periférico encontrado en el escaneo.
class HallazgoBle {
  const HallazgoBle({
    required this.remoteId,
    required this.rssi,
    this.datosFabricante = const {},
  });
  final String remoteId;
  final int rssi;
  final Map<int, List<int>> datosFabricante;
}

/// El usuario negó un permiso de Bluetooth (Android 12+: BLUETOOTH_SCAN / CONNECT).
class PermisoBleDenegado implements Exception {
  const PermisoBleDenegado();
  @override
  String toString() => 'Permiso de Bluetooth denegado';
}

/// Error de una operación GATT (escritura rechazada, tiempo agotado, enlace caído).
class FalloBle implements Exception {
  const FalloBle(this.mensaje, {this.autorizacion = false});
  final String mensaje;

  /// El periférico respondió GATT_INSUFFICIENT_AUTHORIZATION (PIN incorrecto).
  final bool autorizacion;
  @override
  String toString() => 'FalloBle: $mensaje';
}

abstract class BleTransporte {
  AdaptadorBle get adaptadorAhora;
  Stream<AdaptadorBle> get adaptador;

  /// Pide al sistema encender el Bluetooth (Android muestra su diálogo).
  Future<void> encender();

  /// Escanea periféricos que anuncian [servicio] durante [duracion].
  Stream<HallazgoBle> escanear(String servicio, Duration duracion);
  Future<void> detenerEscaneo();

  Future<ConexionBle> conectar(String remoteId);
}

abstract class ConexionBle {
  String get remoteId;

  /// Emite una vez cuando el enlace se cae (o se cierra).
  Future<void> get perdida;

  /// UUID (minúsculas) de los servicios GATT descubiertos.
  Future<Set<String>> servicios();
  Future<List<int>> leer(String servicio, String caracteristica);
  Future<void> escribir(String servicio, String caracteristica, List<int> datos);

  /// Activa notificaciones (escribe la CCCD) y devuelve los valores recibidos.
  Future<Stream<List<int>>> suscribir(String servicio, String caracteristica);
  Future<void> desconectar();
}

/// Transporte sin radio (pruebas y plataformas sin BLE): nunca encuentra nada.
class BleTransporteInactivo implements BleTransporte {
  const BleTransporteInactivo();
  @override
  AdaptadorBle get adaptadorAhora => AdaptadorBle.noDisponible;
  @override
  Stream<AdaptadorBle> get adaptador => const Stream.empty();
  @override
  Future<void> encender() async {}
  @override
  Stream<HallazgoBle> escanear(String servicio, Duration duracion) => const Stream.empty();
  @override
  Future<void> detenerEscaneo() async {}
  @override
  Future<ConexionBle> conectar(String remoteId) => Future.error(const FalloBle('Sin Bluetooth'));
}

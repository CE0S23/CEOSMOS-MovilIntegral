import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'ble_transporte.dart';

/// Transporte BLE real con flutter_blue_plus (licencia `nonprofit`: proyecto
/// escolar). flutter_blue_plus pide en tiempo de ejecución BLUETOOTH_SCAN y
/// BLUETOOTH_CONNECT (Android 12+) o ACCESS_FINE_LOCATION (Android ≤ 11) la primera
/// vez que se escanea o conecta; los permisos se declaran en el AndroidManifest.
///
/// En la PWA usa Web Bluetooth (Chrome/Edge): «escanear» abre el selector del
/// navegador filtrado por el servicio del rol, y el usuario elige el equipo; ese
/// gesto es el permiso. Firefox y Safari no tienen Web Bluetooth: el adaptador se
/// informa como no disponible y la interfaz lo explica.
class BleTransporteFbp implements BleTransporte {
  static const _gattSinAutorizacion = 8; // GATT_INSUFFICIENT_AUTHORIZATION

  static AdaptadorBle _mapa(BluetoothAdapterState s) => switch (s) {
        BluetoothAdapterState.on => AdaptadorBle.encendido,
        BluetoothAdapterState.off ||
        BluetoothAdapterState.turningOff ||
        BluetoothAdapterState.turningOn =>
          AdaptadorBle.apagado,
        BluetoothAdapterState.unavailable => AdaptadorBle.noDisponible,
        BluetoothAdapterState.unauthorized => AdaptadorBle.sinPermiso,
        // En la web «unknown» significa que el navegador no tiene Web Bluetooth.
        _ => kIsWeb ? AdaptadorBle.noDisponible : AdaptadorBle.desconocido,
      };

  @override
  AdaptadorBle get adaptadorAhora => _mapa(FlutterBluePlus.adapterStateNow);

  @override
  Stream<AdaptadorBle> get adaptador => FlutterBluePlus.adapterState.map(_mapa);

  @override
  Future<void> encender() async {
    try {
      await FlutterBluePlus.turnOn(timeout: 20);
    } on FlutterBluePlusException catch (e) {
      throw FalloBle(e.description ?? 'No se encendió el Bluetooth.');
    } on PlatformException catch (e) {
      throw _traducir(e);
    }
  }

  @override
  Stream<HallazgoBle> escanear(String servicio, Duration duracion) async* {
    final vistos = <String>{};
    final salida = StreamController<HallazgoBle>();
    final sub = FlutterBluePlus.onScanResults.listen((lista) {
      for (final r in lista) {
        if (vistos.add(r.device.remoteId.str)) {
          salida.add(HallazgoBle(
            remoteId: r.device.remoteId.str,
            rssi: r.rssi,
            datosFabricante: r.advertisementData.manufacturerData,
          ));
        }
      }
    });
    final fin = FlutterBluePlus.isScanning.where((s) => !s).skip(1).first.then((_) => salida.close());
    try {
      await FlutterBluePlus.startScan(withServices: [Guid(servicio)], timeout: duracion);
    } on PlatformException catch (e) {
      await sub.cancel();
      throw _traducir(e);
    } on FlutterBluePlusException catch (e) {
      await sub.cancel();
      throw FalloBle(e.description ?? 'No se pudo escanear.');
    } catch (e) {
      // Web Bluetooth: el usuario cerró el selector o el navegador lo bloqueó.
      await sub.cancel();
      throw traducirErrorWeb('$e');
    }
    unawaited(fin);
    try {
      yield* salida.stream;
    } finally {
      await sub.cancel();
    }
  }

  @override
  Future<void> detenerEscaneo() => FlutterBluePlus.stopScan();

  @override
  Future<ConexionBle> conectar(String remoteId) async {
    final d = BluetoothDevice.fromId(remoteId);
    try {
      await d.connect(license: License.nonprofit, timeout: const Duration(seconds: 12), mtu: 247);
    } on FlutterBluePlusException catch (e) {
      throw FalloBle(e.description ?? 'No se pudo conectar.');
    } on PlatformException catch (e) {
      throw _traducir(e);
    }
    return _ConexionFbp(d);
  }

  /// Errores de Web Bluetooth (DOMException) a mensajes de CEOSMOS.
  @visibleForTesting
  static Exception traducirErrorWeb(String texto) {
    final t = texto.toLowerCase();
    if (t.contains('cancel')) return const FalloBle('Se cerró el selector sin elegir un equipo.');
    if (t.contains('securityerror') || t.contains('permission') || t.contains('not allowed')) {
      return const PermisoBleDenegado();
    }
    if (t.contains('notfounderror') || t.contains('no devices')) {
      return const FalloBle('El navegador no encontró equipos CEOSMOS cerca.');
    }
    return FalloBle('El navegador no pudo usar Bluetooth ($texto).');
  }

  static Exception _traducir(PlatformException e) {
    final texto = '${e.code} ${e.message}'.toLowerCase();
    if (texto.contains('permission')) return const PermisoBleDenegado();
    if (texto.contains('turned on') || texto.contains('adapter is off')) {
      return const FalloBle('El Bluetooth está apagado.');
    }
    return FalloBle(e.message ?? e.code);
  }
}

class _ConexionFbp implements ConexionBle {
  _ConexionFbp(this._d) {
    _sub = _d.connectionState.listen((s) {
      if (s == BluetoothConnectionState.disconnected && !_perdida.isCompleted) {
        _perdida.complete();
      }
    });
  }

  final BluetoothDevice _d;
  late final StreamSubscription<BluetoothConnectionState> _sub;
  final _perdida = Completer<void>();
  List<BluetoothService>? _servicios;

  @override
  String get remoteId => _d.remoteId.str;

  @override
  Future<void> get perdida => _perdida.future;

  @override
  Future<Set<String>> servicios() async {
    _servicios = await _d.discoverServices(timeout: 10);
    return {for (final s in _servicios!) s.uuid.str128.toLowerCase()};
  }

  BluetoothCharacteristic _c(String servicio, String caracteristica) {
    for (final s in _servicios ?? const <BluetoothService>[]) {
      if (s.uuid.str128.toLowerCase() != servicio) continue;
      for (final c in s.characteristics) {
        if (c.uuid.str128.toLowerCase() == caracteristica) return c;
      }
    }
    throw FalloBle('Característica $caracteristica no encontrada');
  }

  Future<T> _op<T>(Future<T> Function() f) async {
    try {
      return await f();
    } on FlutterBluePlusException catch (e) {
      throw FalloBle(
        e.description ?? 'Operación BLE fallida',
        autorizacion: e.code == BleTransporteFbp._gattSinAutorizacion,
      );
    } on PlatformException catch (e) {
      throw BleTransporteFbp._traducir(e);
    } on TimeoutException {
      throw const FalloBle('El dispositivo no respondió a tiempo.');
    }
  }

  @override
  Future<List<int>> leer(String servicio, String caracteristica) =>
      _op(() => _c(servicio, caracteristica).read(timeout: 8));

  @override
  Future<void> escribir(String servicio, String caracteristica, List<int> datos) =>
      _op(() => _c(servicio, caracteristica).write(datos, withoutResponse: false, timeout: 8));

  @override
  Future<Stream<List<int>>> suscribir(String servicio, String caracteristica) => _op(() async {
        final c = _c(servicio, caracteristica);
        final flujo = c.onValueReceived;
        await c.setNotifyValue(true, timeout: 8);
        return flujo;
      });

  @override
  Future<void> desconectar() async {
    await _sub.cancel();
    try {
      await _d.disconnect(timeout: 5);
    } catch (_) {
      // Ya estaba desconectado.
    }
    if (!_perdida.isCompleted) _perdida.complete();
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'wearable.dart';

/// Cliente TCP real (Android, iOS y escritorio).
class WearableClientImpl extends WearableClient {
  WearableClientImpl() : super.base();

  Socket? _socket;
  StreamSubscription<String>? _lineas;
  WearableEstado _estado = WearableEstado.desconectado;
  String? _error, _deviceId;
  WearableLectura? _ultima;
  final List<int> _muestras = [];
  bool _disposed = false;

  @override
  WearableEstado get estado => _estado;
  @override
  String? get error => _error;
  @override
  String? get deviceId => _deviceId;
  @override
  WearableLectura? get ultima => _ultima;
  @override
  List<int> get muestras => List.unmodifiable(_muestras);

  void _cambio() {
    if (!_disposed) notifyListeners();
  }

  @override
  Future<void> conectar({
    required String deviceId,
    required String host,
    required int port,
  }) async {
    await desconectar();
    _deviceId = deviceId;
    _estado = WearableEstado.conectando;
    _error = null;
    _cambio();
    try {
      final socket = await Socket.connect(host, port, timeout: const Duration(seconds: 6));
      _socket = socket;
      socket.write('CEOSMOS HELLO 1\n');
      _estado = WearableEstado.conectado;
      _cambio();
      _lineas = socket
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            _alRecibir,
            onError: (Object e) => _fallo('Se perdió la conexión con el dispositivo.'),
            onDone: () {
              if (_estado == WearableEstado.conectado) {
                _fallo('El dispositivo cerró la conexión.');
              }
            },
            cancelOnError: true,
          );
    } on SocketException {
      _fallo('No se pudo conectar con $host:$port. Verifica que el dispositivo esté encendido y en la misma red.');
    } on TimeoutException {
      _fallo('El dispositivo no respondió a tiempo.');
    }
  }

  void _alRecibir(String linea) {
    if (linea.length > 512) return;
    try {
      final json = jsonDecode(linea);
      if (json is! Map<String, dynamic>) return;
      final lectura = WearableLectura.parse(json, DateTime.now());
      if (lectura == null) return;
      _ultima = lectura;
      _muestras.add(lectura.heartRate);
      if (_muestras.length > 3600) _muestras.removeAt(0);
      _cambio();
    } on FormatException {
      // Línea que no pertenece al protocolo: se ignora.
    }
  }

  void _fallo(String mensaje) {
    _estado = WearableEstado.error;
    _error = mensaje;
    _cerrarSocket();
    _cambio();
  }

  void _cerrarSocket() {
    unawaited(_lineas?.cancel());
    _lineas = null;
    _socket?.destroy();
    _socket = null;
  }

  @override
  Future<void> desconectar() async {
    _cerrarSocket();
    _estado = WearableEstado.desconectado;
    _error = null;
    _ultima = null;
    _muestras.clear();
    _deviceId = null;
    _cambio();
  }

  @override
  void marcarInicio() => _muestras.clear();

  @override
  void dispose() {
    _disposed = true;
    _cerrarSocket();
    super.dispose();
  }
}

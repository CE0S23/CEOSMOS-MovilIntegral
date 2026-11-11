import 'package:flutter/foundation.dart';

import 'wearable_io.dart' if (dart.library.js_interop) 'wearable_web.dart' as impl;

enum WearableEstado { desconectado, conectando, conectado, error }

/// Lectura de métricas enviada por el wearable.
class WearableLectura {
  const WearableLectura({required this.heartRate, this.steps, required this.at});
  final int heartRate;
  final int? steps;
  final DateTime at;

  /// Protocolo CEOSMOS Band por TCP: una línea JSON por lectura, p. ej.
  /// `{"hr":72,"steps":1240}`. Devuelve null si la línea no es válida.
  static WearableLectura? parse(Map<String, dynamic> json, DateTime now) {
    final hr = json['hr'];
    final steps = json['steps'];
    if (hr is! num || hr < 30 || hr > 230) return null;
    if (steps != null && (steps is! num || steps < 0)) return null;
    return WearableLectura(
      heartRate: hr.round(),
      steps: (steps as num?)?.round(),
      at: now,
    );
  }
}

/// Conexión con el wearable (TCP/IP como transporte primario; BLE queda
/// documentado como respaldo). Expone el estado y las métricas en vivo.
abstract class WearableClient extends ChangeNotifier {
  factory WearableClient() = impl.WearableClientImpl;
  WearableClient.base();

  WearableEstado get estado;
  String? get error;
  String? get deviceId;
  WearableLectura? get ultima;

  /// Frecuencias recibidas desde [marcarInicio] (para la sesión de enfoque).
  List<int> get muestras;

  Future<void> conectar({required String deviceId, required String host, required int port});
  Future<void> desconectar();
  void marcarInicio();

  /// Resumen para guardar en el historial (JSONB `metadata`).
  Map<String, Object> resumenSesion() {
    final m = muestras;
    if (m.isEmpty || deviceId == null) return const {};
    final promedio = m.reduce((a, b) => a + b) / m.length;
    return {
      'wearable': {
        'deviceId': deviceId!,
        'transport': 'TCP',
        'samples': m.length,
        'avgHeartRate': double.parse(promedio.toStringAsFixed(1)),
        'minHeartRate': m.reduce((a, b) => a < b ? a : b),
        'maxHeartRate': m.reduce((a, b) => a > b ? a : b),
        if (ultima?.steps != null) 'lastSteps': ultima!.steps!,
      },
    };
  }
}

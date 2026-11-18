import 'dart:math';

import '../data/api_client.dart';

/// Reintento controlado con espera exponencial y variación aleatoria (P12-O3).
///
/// Espera `base · 2^intento` (2 s, 4 s, 8 s, 16 s, 32 s…) hasta `maximo`, con ±`variacion`
/// para que muchos teléfonos que recuperan la red a la vez no reintenten en el mismo
/// instante. Solo se reintenta lo que puede salir bien más tarde: sin red, tiempo
/// agotado, 408, 429 y 5xx. Un 4xx (400, 403, 404, 409…) es definitivo: repetirlo daría
/// el mismo resultado, y un 401 lo resuelve el cierre de sesión.
///
/// La idempotencia de las escrituras la da el `clientId` de cada sesión de enfoque
/// (P11-D01): todos los reintentos llevan el mismo, y el servidor devuelve la sesión que
/// ya tenía en lugar de crear otra.
class PoliticaReintento {
  const PoliticaReintento({
    this.base = const Duration(seconds: 2),
    this.maximo = const Duration(seconds: 60),
    this.variacion = 0.2,
    this.azar,
  });

  final Duration base, maximo;
  final double variacion;
  final Random? azar;

  /// Espera antes del reintento número [intento] (0 = primer reintento).
  Duration espera(int intento) {
    final exp = base.inMilliseconds * pow(2, min(intento, 20));
    final tope = min(exp.toDouble(), maximo.inMilliseconds.toDouble());
    final r = (azar ?? Random()).nextDouble() * 2 - 1; // [-1, 1)
    return Duration(milliseconds: (tope * (1 + variacion * r)).round());
  }

  /// ¿Puede salir bien si se repite más tarde?
  static bool reintentable(ApiException e) {
    final s = e.statusCode;
    return s == null || s == 408 || s == 429 || s >= 500;
  }
}

import 'package:flutter/foundation.dart';

/// Configuración de CEOSMOS. No contiene secretos.
///
/// La URL de la API se define al compilar:
///   flutter run --dart-define=CEOSMOS_API_URL=https://mi-api.example.com/api
/// Sin valor, en Android (emulador) se usa la API local del equipo anfitrión
/// (10.0.2.2) y en web/escritorio `localhost`.
class AppConfig {
  static const _definida = String.fromEnvironment('CEOSMOS_API_URL');

  static String get apiBaseUrl {
    if (_definida.isNotEmpty) return _definida;
    final android = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    return android ? 'http://10.0.2.2:8080/api' : 'http://localhost:8080/api';
  }

  /// Límite de la caché local de imágenes (reporte de avances: 150–200 MB, LRU).
  static const mediaCacheBytes = 150 * 1024 * 1024;

  /// Tamaño máximo admitido por imagen (WebP/JPEG ≤ 2 MB).
  static const maxImageBytes = 2 * 1024 * 1024;
}

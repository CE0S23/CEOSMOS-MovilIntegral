import 'package:flutter/foundation.dart';

/// Configuración de CEOSMOS. No contiene secretos.
///
/// La URL de la API se define al compilar:
///   flutter run --dart-define=CEOSMOS_API_URL=https://mi-api.example.com/api
/// Sin valor:
///  * en **release** se usa la API de producción (blindaje 22/11: una v2 se
///    compiló sin la URL y apuntaba a 10.0.2.2, sin conexión en los teléfonos);
///  * en depuración, en Android (emulador) la API local del equipo anfitrión
///    (10.0.2.2) y en web/escritorio `localhost`.
class AppConfig {
  static const _definida = String.fromEnvironment('CEOSMOS_API_URL');

  /// API de producción (Vercel).
  static const produccion = 'https://ceosmos-api.vercel.app/api';

  static String get apiBaseUrl => resolverApi(
        definida: _definida,
        release: kReleaseMode,
        android: !kIsWeb && defaultTargetPlatform == TargetPlatform.android,
      );

  /// Regla de selección de la URL, separada para poder probarla.
  @visibleForTesting
  static String resolverApi({
    required String definida,
    required bool release,
    required bool android,
  }) {
    if (definida.isNotEmpty) return definida;
    if (release) return produccion;
    return android ? 'http://10.0.2.2:8080/api' : 'http://localhost:8080/api';
  }

  /// Límite de la caché local de imágenes (reporte de avances: 150–200 MB, LRU).
  static const mediaCacheBytes = 150 * 1024 * 1024;

  /// Tamaño máximo admitido por imagen (WebP/JPEG ≤ 2 MB).
  static const maxImageBytes = 2 * 1024 * 1024;
}

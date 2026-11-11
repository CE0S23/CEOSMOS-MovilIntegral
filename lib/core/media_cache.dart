import 'dart:typed_data';

import 'media_cache_io.dart' if (dart.library.js_interop) 'media_cache_web.dart' as impl;

/// Caché local de imágenes con límite de espacio y reemplazo LRU
/// (reporte de avances: 150–200 MB; imágenes WebP/JPEG de hasta 2 MB).
abstract class MediaCache {
  static final MediaCache instance = impl.crearCache();

  /// Bytes de la imagen (desde caché o descargados). Lanza [MediaCacheError].
  Future<Uint8List> imagen(String url);

  /// Espacio ocupado actualmente (bytes).
  Future<int> tamano();

  Future<void> limpiar();
}

class MediaCacheError implements Exception {
  const MediaCacheError(this.message);
  final String message;
  @override
  String toString() => message;
}

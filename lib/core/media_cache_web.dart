import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'config.dart';
import 'media_cache.dart';

MediaCache crearCache() => _WebMediaCache();

/// En navegador la caché HTTP la administra el propio navegador.
class _WebMediaCache implements MediaCache {
  @override
  Future<Uint8List> imagen(String url) async {
    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) {
      throw MediaCacheError('No se pudo descargar la imagen (HTTP ${res.statusCode}).');
    }
    if (res.bodyBytes.length > AppConfig.maxImageBytes) {
      throw const MediaCacheError('La imagen supera el límite de 2 MB.');
    }
    return res.bodyBytes;
  }

  @override
  Future<int> tamano() async => 0;
  @override
  Future<void> limpiar() async {}
}

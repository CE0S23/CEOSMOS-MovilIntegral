import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'config.dart';
import 'media_cache.dart';

MediaCache crearCache() => DiskMediaCache();

/// Caché en disco: un archivo por URL (SHA-1). El último acceso se registra en
/// la fecha de modificación; al superar el límite se borran los menos usados.
class DiskMediaCache implements MediaCache {
  DiskMediaCache({
    this.maxBytes = AppConfig.mediaCacheBytes,
    this.maxImageBytes = AppConfig.maxImageBytes,
    Future<Directory> Function()? directorio,
    http.Client? client,
  }) : _directorio = directorio,
       _http = client ?? http.Client();

  final int maxBytes, maxImageBytes;
  final Future<Directory> Function()? _directorio;
  final http.Client _http;
  final Map<String, Future<Uint8List>> _enCurso = {};
  Directory? _dir;
  Future<void> _cola = Future.value();

  /// Formatos admitidos por el reporte de avances.
  static const _tipos = {'image/jpeg', 'image/jpg', 'image/webp'};

  Future<Directory> _carpeta() async {
    if (_dir != null) return _dir!;
    final base = await (_directorio?.call() ?? getApplicationSupportDirectory());
    final dir = Directory('${base.path}${Platform.pathSeparator}ceosmos_media_cache');
    await dir.create(recursive: true);
    return _dir = dir;
  }

  @override
  Future<Uint8List> imagen(String url) => _enCurso.putIfAbsent(
    url,
    // Bloque con llaves: devolver el Future eliminado haría que whenComplete
    // se esperara a sí mismo.
    () => _obtener(url).whenComplete(() {
      _enCurso.remove(url);
    }),
  );

  Future<Uint8List> _obtener(String url) async {
    final dir = await _carpeta();
    final archivo = File('${dir.path}${Platform.pathSeparator}${sha1.convert(url.codeUnits)}');
    if (await archivo.exists()) {
      await archivo.setLastModified(DateTime.now()); // uso reciente (LRU)
      return archivo.readAsBytes();
    }
    final uri = Uri.tryParse(url);
    if (uri == null || !(uri.isScheme('https') || uri.isScheme('http'))) {
      throw const MediaCacheError('La dirección de la imagen no es válida.');
    }
    final http.Response res;
    try {
      res = await _http.get(uri).timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw const MediaCacheError('La imagen tardó demasiado en descargarse.');
    } on http.ClientException {
      throw const MediaCacheError('Sin conexión para descargar la imagen.');
    }
    if (res.statusCode != 200) {
      throw MediaCacheError('No se pudo descargar la imagen (HTTP ${res.statusCode}).');
    }
    final tipo = (res.headers['content-type'] ?? '').split(';').first.trim().toLowerCase();
    if (!_tipos.contains(tipo)) {
      throw const MediaCacheError('Formato no admitido: solo imágenes JPEG o WebP.');
    }
    if (res.bodyBytes.length > maxImageBytes) {
      throw const MediaCacheError('La imagen supera el límite de 2 MB.');
    }
    final temporal = File('${archivo.path}.tmp');
    await temporal.writeAsBytes(res.bodyBytes, flush: true);
    await temporal.rename(archivo.path);
    unawaited(recortar());
    return res.bodyBytes;
  }

  /// Recorta la caché; los recortes se encadenan para que dos descargas
  /// simultáneas no borren de más con la misma lista de archivos.
  Future<void> recortar() => _cola = _cola.then((_) => _recortar()).catchError((_) {});

  /// Borra los archivos usados hace más tiempo hasta quedar bajo el límite.
  Future<void> _recortar() async {
    final dir = await _carpeta();
    final archivos = <File, FileStat>{};
    await for (final e in dir.list()) {
      if (e is File && !e.path.endsWith('.tmp')) archivos[e] = await e.stat();
    }
    var total = archivos.values.fold<int>(0, (s, st) => s + st.size);
    if (total <= maxBytes) return;
    final orden = archivos.entries.toList()
      ..sort((a, b) => a.value.modified.compareTo(b.value.modified));
    for (final e in orden) {
      if (total <= maxBytes) break;
      try {
        await e.key.delete();
        total -= e.value.size;
      } on PathNotFoundException {
        total -= e.value.size; // ya no existe
      } on FileSystemException {
        // En uso por otra lectura: se intenta en el siguiente recorte.
      }
    }
  }

  @override
  Future<int> tamano() async {
    final dir = await _carpeta();
    var total = 0;
    await for (final e in dir.list()) {
      if (e is File) total += await e.length();
    }
    return total;
  }

  @override
  Future<void> limpiar() async {
    final dir = await _carpeta();
    await for (final e in dir.list()) {
      if (e is File) await e.delete();
    }
  }
}

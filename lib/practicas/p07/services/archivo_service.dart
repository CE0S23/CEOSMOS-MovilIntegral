import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

class ArchivoSeleccionado {
  const ArchivoSeleccionado(this.nombre, this.bytes, this.tipo);
  final String nombre;
  final Uint8List bytes;
  final String tipo;
}

class ArchivoService {
  static const maxBytes = 300 * 1024;

  Future<ArchivoSeleccionado?> elegir() async {
    final resultado = await FilePicker.platform.pickFiles(withData: true);
    if (resultado == null || resultado.files.isEmpty) return null;
    final archivo = resultado.files.single;
    if (archivo.size > maxBytes) {
      throw ArgumentError('El archivo debe medir como máximo 300 KB');
    }
    final bytes = archivo.bytes;
    if (bytes == null) throw StateError('No se pudo leer el archivo');
    final extension = archivo.extension?.toLowerCase() ?? '';
    final tipo = switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'gif' => 'image/gif',
      'pdf' => 'application/pdf',
      'txt' => 'text/plain',
      _ => 'application/octet-stream',
    };
    return ArchivoSeleccionado(archivo.name, bytes, tipo);
  }

  String codificar(ArchivoSeleccionado archivo) => base64Encode(archivo.bytes);
}

import 'package:cloud_firestore/cloud_firestore.dart';

class Mensaje {
  const Mensaje({
    required this.id,
    required this.emisorId,
    required this.emisorNombre,
    required this.emisorRol,
    required this.texto,
    required this.tipo,
    this.archivoUrl,
    this.archivoBase64,
    this.archivoNombre,
    this.archivoTipo,
    this.hora,
  });

  final String id;
  final String emisorId;
  final String emisorNombre;
  final String emisorRol;
  final String texto;
  final String tipo;
  final String? archivoUrl;
  final String? archivoBase64;
  final String? archivoNombre;
  final String? archivoTipo;
  final DateTime? hora;

  factory Mensaje.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Mensaje(
      id: doc.id,
      emisorId: d['emisorId'] as String? ?? '',
      emisorNombre: d['emisorNombre'] as String? ?? '',
      emisorRol: d['emisorRol'] as String? ?? '',
      texto: d['texto'] as String? ?? '',
      tipo: d['tipo'] as String? ?? 'mensaje',
      archivoUrl: d['archivoUrl'] as String?,
      archivoBase64: d['archivoBase64'] as String?,
      archivoNombre: d['archivoNombre'] as String?,
      archivoTipo: d['archivoTipo'] as String?,
      hora: (d['hora'] as Timestamp?)?.toDate(),
    );
  }
}

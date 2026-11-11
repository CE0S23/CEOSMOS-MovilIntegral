import 'package:cloud_firestore/cloud_firestore.dart';

class Dispositivo {
  const Dispositivo({
    required this.uid,
    required this.nombre,
    required this.rol,
    required this.conectado,
    this.ultimaConexion,
  });

  final String uid;
  final String nombre;
  final String rol;
  final bool conectado;
  final DateTime? ultimaConexion;

  bool get enLinea =>
      conectado &&
      ultimaConexion != null &&
      DateTime.now().difference(ultimaConexion!).inSeconds < 90;

  factory Dispositivo.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Dispositivo(
      uid: doc.id,
      nombre: d['nombre'] as String? ?? 'Dispositivo',
      rol: d['rol'] as String? ?? '',
      conectado: d['conectado'] as bool? ?? false,
      ultimaConexion: (d['ultimaConexion'] as Timestamp?)?.toDate(),
    );
  }
}

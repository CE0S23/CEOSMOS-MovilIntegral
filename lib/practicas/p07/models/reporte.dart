import 'package:cloud_firestore/cloud_firestore.dart';

class Reporte {
  const Reporte({
    required this.id,
    required this.turno,
    required this.titulo,
    required this.equipo,
    required this.descripcion,
    required this.prioridad,
    required this.estado,
    required this.usuarioId,
    required this.usuarioTag,
    required this.usuarioNombre,
    required this.asignadoA,
    required this.activo,
    required this.pendiente,
    this.fecha,
  });

  final String id;
  final int turno;
  final String titulo;
  final String equipo;
  final String descripcion;
  final String prioridad;
  final String estado;
  final String usuarioId;
  final String usuarioTag;
  final String usuarioNombre;
  final String asignadoA;
  final bool activo;
  final bool pendiente;
  final DateTime? fecha;

  factory Reporte.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Reporte(
      id: doc.id,
      turno: (d['turno'] as num?)?.toInt() ?? 0,
      titulo: d['titulo'] as String? ?? d['equipo'] as String? ?? '',
      equipo: d['equipo'] as String? ?? '',
      descripcion: d['descripcion'] as String? ?? '',
      prioridad: d['prioridad'] as String? ?? 'Media',
      estado: d['estado'] as String? ?? 'Abierto',
      usuarioId: d['usuarioId'] as String? ?? '',
      usuarioTag: d['usuarioTag'] as String? ?? '',
      usuarioNombre: d['usuarioNombre'] as String? ?? '',
      asignadoA: d['asignadoA'] as String? ?? 'agente',
      activo: d['activo'] as bool? ?? false,
      pendiente: doc.metadata.hasPendingWrites,
      fecha: (d['fecha'] as Timestamp?)?.toDate(),
    );
  }
}

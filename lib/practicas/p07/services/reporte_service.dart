import '../firebase_p07.dart'; // [CEOSMOS]
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/dispositivo.dart';
import '../models/reporte.dart';

enum ResultadoAlta { guardado, pendiente, repetido }

class ReporteService {
  final _db = FirebaseP07.db; // [CEOSMOS] app Firebase con nombre

  CollectionReference<Map<String, dynamic>> get _reportes =>
      _db.collection('reportes');
  CollectionReference<Map<String, dynamic>> get _turnos =>
      _db.collection('turnos');

  Stream<List<Reporte>> escuchar({String? asignadoA}) {
    Query<Map<String, dynamic>> consulta = _reportes;
    if (asignadoA != null) {
      consulta = consulta.where('asignadoA', isEqualTo: asignadoA);
    }
    return consulta
        .snapshots(includeMetadataChanges: true)
        .map(
          (snapshot) =>
              snapshot.docs.map(Reporte.fromDoc).where((r) => r.activo).toList()
                ..sort(_compararFecha),
        );
  }

  Future<List<Reporte>> consultarListaUsuario(String uid) async {
    final consulta = _reportes.where('usuarioId', isEqualTo: uid);
    QuerySnapshot<Map<String, dynamic>> snapshot;
    try {
      snapshot = await consulta.get().timeout(const Duration(seconds: 5));
    } on TimeoutException {
      snapshot = await consulta.get(const GetOptions(source: Source.cache));
    } on FirebaseException catch (e) {
      if (e.code != 'unavailable') rethrow;
      snapshot = await consulta.get(const GetOptions(source: Source.cache));
    }
    return snapshot.docs.map(Reporte.fromDoc).where((r) => r.activo).toList()
      ..sort(_compararFecha);
  }

  Future<Reporte?> consultarId(String id) async {
    try {
      final ref = _reportes.doc(id.trim().toUpperCase());
      DocumentSnapshot<Map<String, dynamic>> doc;
      try {
        doc = await ref.get().timeout(const Duration(seconds: 5));
      } on TimeoutException {
        doc = await ref.get(const GetOptions(source: Source.cache));
      }
      if (!doc.exists || doc.data()?['activo'] != true) return null;
      return Reporte.fromDoc(doc);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') return null;
      if (e.code == 'unavailable') {
        final doc = await _reportes
            .doc(id.trim().toUpperCase())
            .get(const GetOptions(source: Source.cache));
        return doc.exists && doc.data()?['activo'] == true
            ? Reporte.fromDoc(doc)
            : null;
      }
      rethrow;
    }
  }

  Stream<Reporte?> escucharId(String id) => _reportes
      .doc(id)
      .snapshots()
      .map((doc) => doc.exists ? Reporte.fromDoc(doc) : null);

  static int _compararFecha(Reporte a, Reporte b) =>
      (b.fecha ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(
        a.fecha ?? DateTime.fromMillisecondsSinceEpoch(0),
      );

  Future<ResultadoAlta> crear({
    required String id,
    required String titulo,
    required String equipo,
    required String descripcion,
    required String prioridad,
    required Dispositivo creador,
  }) async {
    if (!creador.rol.startsWith('usuario')) {
      throw StateError('Solo los usuarios pueden crear solicitudes');
    }
    final ref = _reportes.doc(id.trim().toUpperCase());
    try {
      final existente = await ref.get().timeout(const Duration(seconds: 5));
      if (existente.exists) return ResultadoAlta.repetido;
    } on TimeoutException {
      // La escritura puede quedar en la caché hasta recuperar la conexión.
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') return ResultadoAlta.repetido;
      if (e.code != 'unavailable') rethrow;
    }

    QuerySnapshot<Map<String, dynamic>>? turnos;
    try {
      turnos = await _turnos.get().timeout(const Duration(seconds: 5));
    } on TimeoutException {
      turnos = await _turnos.get(const GetOptions(source: Source.cache));
    } on FirebaseException catch (e) {
      if (e.code != 'unavailable') rethrow;
      turnos = await _turnos.get(const GetOptions(source: Source.cache));
    }
    final ocupados = {
      for (final doc in turnos.docs)
        if (doc.data()['ocupado'] == true) int.tryParse(doc.id),
    };
    final libres = [
      for (var n = 1; n <= 50; n++)
        if (!ocupados.contains(n)) n,
    ];
    if (libres.isEmpty) throw StateError('No hay turnos disponibles');

    for (final turno in libres.take(3)) {
      final batch = _db.batch();
      batch.set(ref, {
        'id': ref.id,
        'turno': turno,
        'titulo': titulo.trim(),
        'equipo': equipo.trim(),
        'descripcion': descripcion.trim(),
        'prioridad': prioridad,
        'estado': 'Abierto',
        'usuarioId': creador.uid,
        'usuarioTag': creador.rol,
        'usuarioNombre': creador.nombre,
        'asignadoA': 'agente',
        'fecha': FieldValue.serverTimestamp(),
        'actualizadoEn': FieldValue.serverTimestamp(),
        'activo': true,
      });
      batch.set(_turnos.doc('$turno'), {
        'ocupado': true,
        'reporteId': ref.id,
        'usuarioTag': creador.rol,
      });
      try {
        await batch.commit().timeout(const Duration(seconds: 5));
        return ResultadoAlta.guardado;
      } on TimeoutException {
        return ResultadoAlta.pendiente;
      } on FirebaseException catch (e) {
        if (e.code != 'permission-denied') rethrow;
        try {
          if ((await ref.get()).exists) return ResultadoAlta.repetido;
        } on FirebaseException catch (consultaError) {
          if (consultaError.code == 'permission-denied') {
            return ResultadoAlta.repetido;
          }
          rethrow;
        }
      }
    }
    throw StateError('No se pudo reservar un turno tras tres intentos');
  }

  Future<void> actualizar(
    Reporte reporte, {
    String? prioridad,
    String? estado,
  }) async {
    if (reporte.estado == 'Resuelto') {
      throw StateError('Un ticket resuelto no puede reabrirse');
    }
    final cambios = <String, dynamic>{
      'prioridad': ?prioridad,
      'estado': ?estado,
      'actualizadoEn': FieldValue.serverTimestamp(),
    };
    if (estado == 'Resuelto') {
      await _actualizarYLiberar(reporte, cambios);
    } else {
      await _reportes.doc(reporte.id).update(cambios);
    }
  }

  Future<void> escalar(Reporte reporte) async {
    if (reporte.asignadoA != 'agente' || reporte.estado == 'Resuelto') {
      throw StateError('El ticket no puede escalarse');
    }
    await _reportes.doc(reporte.id).update({
      'asignadoA': 'admin',
      'estado': 'Escalado',
      'actualizadoEn': FieldValue.serverTimestamp(),
    });
  }

  Future<void> devolver(Reporte reporte) async {
    if (reporte.asignadoA != 'admin' || reporte.estado == 'Resuelto') {
      throw StateError('El ticket no puede devolverse');
    }
    await _reportes.doc(reporte.id).update({
      'asignadoA': 'agente',
      'estado': 'Abierto',
      'actualizadoEn': FieldValue.serverTimestamp(),
    });
  }

  Future<void> eliminar(Reporte reporte) async {
    if (reporte.estado == 'Resuelto') {
      await _reportes.doc(reporte.id).update({
        'activo': false,
        'actualizadoEn': FieldValue.serverTimestamp(),
      });
    } else {
      await _actualizarYLiberar(reporte, {
        'activo': false,
        'actualizadoEn': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _actualizarYLiberar(
    Reporte reporte,
    Map<String, dynamic> cambios,
  ) async {
    final turnoRef = _turnos.doc('${reporte.turno}');
    final turnoDoc = await turnoRef.get();
    if (!turnoDoc.exists ||
        turnoDoc.data()?['reporteId'] != reporte.id ||
        turnoDoc.data()?['ocupado'] != true) {
      throw StateError('La reserva del turno ya no corresponde a este ticket');
    }
    final batch = _db.batch();
    batch.update(_reportes.doc(reporte.id), cambios);
    batch.update(turnoRef, {
      'ocupado': false,
      'reporteId': null,
      'usuarioTag': null,
    });
    await batch.commit();
  }
}

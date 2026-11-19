import '../firebase_p07.dart'; // [CEOSMOS]
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/dispositivo.dart';
import '../models/mensaje.dart';

class MensajeService {
  final _db = FirebaseP07.db; // [CEOSMOS] app Firebase con nombre

  CollectionReference<Map<String, dynamic>> _mensajes(String reporteId) =>
      _db.collection('conversaciones').doc(reporteId).collection('mensajes');

  Stream<QuerySnapshot<Map<String, dynamic>>> escucharRaw(String reporteId) =>
      // [CEOSMOS] Con los cambios de metadatos llega también la confirmación
      // del servidor: sin ellos, un mensaje propio podía quedarse en
      // «Pendiente» aunque ya estuviera guardado (P7, 19/11).
      _mensajes(reporteId).orderBy('hora').snapshots(includeMetadataChanges: true);

  Future<List<Mensaje>> consultar(String reporteId) async {
    final s = await _mensajes(reporteId).orderBy('hora').get();
    return s.docs.map(Mensaje.fromDoc).toList();
  }

  Stream<int> contador(String uid) => _db
      .collection('contadores')
      .doc(uid)
      .snapshots()
      .map((s) => (s.data()?['enviados'] as num?)?.toInt() ?? 0);

  Future<int> consultarContador(String uid) async {
    final s = await _db.collection('contadores').doc(uid).get();
    return (s.data()?['enviados'] as num?)?.toInt() ?? 0;
  }

  Future<void> enviar({
    required Dispositivo emisor,
    required String reporteId,
    required String texto,
    String tipo = 'mensaje',
    String? archivoUrl,
    String? archivoBase64,
    String? archivoNombre,
    String? archivoTipo,
  }) async {
    if (reporteId.trim().isEmpty) throw ArgumentError('Ticket inválido');
    if (texto.trim().isEmpty) throw ArgumentError('Mensaje vacío');
    final batch = _db.batch();
    batch.set(_mensajes(reporteId).doc(), {
      'emisorId': emisor.uid,
      'emisorNombre': emisor.nombre,
      'emisorRol': emisor.rol,
      'texto': texto.trim(),
      'tipo': tipo,
      'archivoUrl': archivoUrl,
      'archivoBase64': archivoBase64,
      'archivoNombre': archivoNombre,
      'archivoTipo': archivoTipo,
      'hora': FieldValue.serverTimestamp(),
    });
    batch.set(_db.collection('contadores').doc(emisor.uid), {
      'enviados': FieldValue.increment(1),
    }, SetOptions(merge: true));
    await batch.commit();
  }

  Future<void> limpiar(String reporteId) async {
    final emisores = <String>{};
    while (true) {
      final pagina = await _mensajes(reporteId).limit(400).get();
      if (pagina.docs.isEmpty) break;
      final batch = _db.batch();
      for (final doc in pagina.docs) {
        final uid = doc.data()['emisorId'] as String?;
        if (uid != null) emisores.add(uid);
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
    for (final uid in emisores) {
      final ref = _db.collection('contadores').doc(uid);
      if ((await ref.get()).exists) await ref.update({'enviados': 0});
    }
  }
}

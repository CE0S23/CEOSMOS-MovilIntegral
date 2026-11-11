import '../firebase_p07.dart'; // [CEOSMOS]

import '../models/dispositivo.dart';

class DispositivoService {
  final _db = FirebaseP07.db; // [CEOSMOS] app Firebase con nombre

  Stream<List<Dispositivo>> escuchar() => _db
      .collection('dispositivos')
      .snapshots()
      .map((s) => s.docs.map(Dispositivo.fromDoc).toList());

  Future<List<Dispositivo>> consultar() async {
    final s = await _db.collection('dispositivos').get();
    return s.docs.map(Dispositivo.fromDoc).toList();
  }

  Future<void> cambiarRol(String uid, String rol) =>
      _db.collection('dispositivos').doc(uid).update({'rol': rol});
}

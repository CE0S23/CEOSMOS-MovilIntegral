import '../firebase_p07.dart'; // [CEOSMOS]
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';

import '../models/dispositivo.dart';

class AuthService extends ChangeNotifier with WidgetsBindingObserver {
  AuthService() {
    WidgetsBinding.instance.addObserver(this);
  }

  final _auth = FirebaseP07.auth; // [CEOSMOS] app Firebase con nombre
  final _db = FirebaseP07.db; // [CEOSMOS] app Firebase con nombre
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _subscription;
  Timer? _latido;
  bool _enPrimerPlano = true;
  Dispositivo? actual;

  String? get uid => _auth.currentUser?.uid;

  Future<void> iniciar() async {
    final user = _auth.currentUser;
    if (user == null) return;
    if (user.isAnonymous || user.email == null) {
      await _auth.signOut();
      return;
    }
    final ref = _db.collection('dispositivos').doc(user.uid);
    final doc = await ref.get();
    if (doc.exists) {
      _escuchar(ref);
      await _crearContador(user.uid);
      await _presencia(true);
    } else {
      await _auth.signOut();
    }
  }

  Future<void> entrar(String? rolEsperado, String correo, String clave) async {
    final credencial = await _auth.signInWithEmailAndPassword(
      email: correo.trim(),
      password: clave,
    );
    final user = credencial.user;
    if (user == null) {
      throw StateError('No fue posible iniciar sesión');
    }
    final ref = _db.collection('dispositivos').doc(user.uid);
    final doc = await ref.get(const GetOptions(source: Source.server));
    if (!doc.exists) {
      await _auth.signOut();
      throw StateError('Cuenta no autorizada');
    }
    if (rolEsperado != null && doc.data()?['rol'] != rolEsperado) {
      await _auth.signOut();
      throw StateError('La cuenta no corresponde al rol de la URL');
    }
    await _crearContador(user.uid);
    _escuchar(ref);
    await _presencia(true);
  }

  Future<void> salir() async {
    await _presencia(false);
    await _subscription?.cancel();
    _subscription = null;
    _latido?.cancel();
    _latido = null;
    await _auth.signOut();
    actual = null;
    notifyListeners();
  }

  Future<void> _crearContador(String uid) async {
    final ref = _db.collection('contadores').doc(uid);
    if (!(await ref.get()).exists) {
      await ref.set({'enviados': 0});
    }
  }

  void _escuchar(DocumentReference<Map<String, dynamic>> ref) {
    _subscription?.cancel();
    _subscription = ref.snapshots().listen((doc) {
      actual = doc.exists ? Dispositivo.fromDoc(doc) : null;
      notifyListeners();
    });
    _latido?.cancel();
    _latido = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_enPrimerPlano) _presencia(true);
    });
  }

  Future<void> _presencia(bool conectado) async {
    final id = uid;
    if (id == null || actual == null && !conectado) return;
    try {
      await _db
          .collection('dispositivos')
          .doc(id)
          .update({
            'conectado': conectado,
            'ultimaConexion': FieldValue.serverTimestamp(),
          })
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // La marca de tiempo determina la presencia si el cierre no llega al servidor.
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _enPrimerPlano = true;
      _presencia(true);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _enPrimerPlano = false;
      _presencia(false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _latido?.cancel();
    _subscription?.cancel();
    super.dispose();
  }
}

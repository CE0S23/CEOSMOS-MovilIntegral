// [CEOSMOS] Archivo agregado durante la integración.
//
// La Práctica 7 usaba la app Firebase [DEFAULT] inicializada con
// android/app/google-services.json. Dentro de CEOSMOS se registra como una app
// con nombre propio («practica7») para que su sesión de Firebase Auth, su caché
// de Firestore y su configuración no se mezclen con CEOSMOS ni con otras
// prácticas. Los valores son los del google-services.json entregado
// (proyecto practica7-8-941cb, app Android com.example.practica7).
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
// ignore: implementation_imports
import 'package:cloud_firestore_platform_interface/src/method_channel/method_channel_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'firebase_options.dart';

class FirebaseP07 {
  static const nombre = 'practica7';

  /// Configuración Android pública de la práctica (google-services.json).
  static const android = FirebaseOptions(
    apiKey: 'AIzaSyDWfa1S8kAuN471DJnrRhxCpRTZObOi0B4',
    appId: '1:987714720406:android:75b0c3c03a8e934490a8b7',
    messagingSenderId: '987714720406',
    projectId: 'practica7-8-941cb',
    storageBucket: 'practica7-8-941cb.firebasestorage.app',
  );

  static FirebaseApp get app => Firebase.app(nombre);
  static FirebaseAuth get auth => FirebaseAuth.instanceFor(app: app);
  static FirebaseFirestore get db => FirebaseFirestore.instanceFor(app: app);

  static Future<void>? _inicio;

  /// Inicializa una sola vez la app con nombre y la persistencia de Firestore
  /// (equivale a lo que hacía `main()` en la práctica original).
  static Future<void> inicializar() =>
      _inicio ??= _inicializar().catchError((Object e) {
        _inicio = null; // permite reintentar si no había red
        throw e;
      });

  static Future<void> _inicializar() async {
    if (!Firebase.apps.any((a) => a.name == nombre)) {
      await Firebase.initializeApp(
        name: nombre,
        options: kIsWeb ? DefaultFirebaseOptions.web : android,
      );
    }
    // cloud_firestore crea su delegado «prototipo» con Firebase.app() ([DEFAULT])
    // aunque se pida otra app, y CEOSMOS no tiene app [DEFAULT]. Se usa como
    // prototipo la app de la práctica; solo sirve para crear el delegado por app.
    try {
      FirebaseFirestorePlatform.instance;
    } on FirebaseException {
      FirebaseFirestorePlatform.instance = MethodChannelFirebaseFirestore(
        app: app,
        databaseId: '(default)',
      );
    }
    db.settings = const Settings(persistenceEnabled: true);
  }
}

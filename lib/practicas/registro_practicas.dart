import 'package:flutter/widgets.dart';

import 'bd_flutter/main.dart' as bd_flutter;
import 'eval2/main.dart' as eval2;
import 'examen1/main.dart' as examen1;
import 'p03_04/main.dart' as p03_04;
import 'p05/main.dart' as p05;
import 'p06/mobile_connect_app.dart' as p06;
import 'p07/main.dart' as p07;

/// Cómo se ejecuta la práctica dentro de CEOSMOS.
enum TipoPractica {
  /// App Flutter montada en una ruta de CEOSMOS con su propio MaterialApp.
  flutter,

  /// Actividad Android (Kotlin/Compose) incluida en el APK de CEOSMOS.
  nativa,
}

class Practica {
  const Practica({
    required this.id,
    required this.numero,
    required this.titulo,
    required this.descripcion,
    required this.stack,
    required this.datos,
    required this.tipo,
    this.construir,
    this.requisito,
  });

  final String id;
  final String numero;
  final String titulo;
  final String descripcion;
  final String stack;

  /// Base de datos o servicio propio de la práctica (nunca el de CEOSMOS).
  final String datos;
  final TipoPractica tipo;

  /// Widget raíz de la práctica (solo [TipoPractica.flutter]).
  final WidgetBuilder? construir;

  /// Condición externa para usarla (por ejemplo, un backend local).
  final String? requisito;
}

final List<Practica> practicas = [
  Practica(
    id: 'p03_04',
    numero: 'P3-4',
    titulo: 'ConsultaWeb',
    descripcion:
        'Consulta un servicio web público y registra usuarios en una base local.',
    stack: 'Flutter · http · Floor',
    datos: 'SQLite propio (p03_04_usuarios.db)',
    tipo: TipoPractica.flutter,
    construir: (_) => const p03_04.ConsultaWebApp(),
  ),
  Practica(
    id: 'p05',
    numero: 'P5',
    titulo: 'AccesoSeguro',
    descripcion:
        'Inicio de sesión validado en Kotlin por un canal de plataforma.',
    stack: 'Flutter + Kotlin (MethodChannel)',
    datos: 'Sin base de datos (validación local de la práctica)',
    tipo: TipoPractica.flutter,
    construir: (_) => const p05.AccesoSeguroApp(),
  ),
  Practica(
    id: 'p06',
    numero: 'P6',
    titulo: 'MobileConnect',
    descripcion:
        'Chat por TCP (puerto 5000) entre dos teléfonos de la misma red Wi-Fi.',
    stack: 'Flutter + Kotlin (sockets TCP)',
    datos: 'Sin base de datos (mensajes en memoria)',
    tipo: TipoPractica.flutter,
    construir: (_) => const p06.MobileConnectApp(),
  ),
  Practica(
    id: 'examen1',
    numero: 'Examen 1',
    titulo: 'Incidencias de soporte',
    descripcion: 'Registro, consulta y eliminación de incidencias sin conexión.',
    stack: 'Flutter · SharedPreferences',
    datos: 'SharedPreferences (clave examen1.incidencias)',
    tipo: TipoPractica.flutter,
    construir: (_) => const examen1.IncidenciasApp(),
  ),
  Practica(
    id: 'p07',
    numero: 'P7',
    titulo: 'Sistema de tickets',
    descripcion:
        'Reportes por rol, chat con archivos y presencia de dispositivos.',
    stack: 'Flutter · Firebase Auth · Firestore',
    datos: 'Firebase practica7-8-941cb (app «practica7»)',
    tipo: TipoPractica.flutter,
    construir: (_) => const p07.Practica7Entrada(),
    requisito: 'Requiere las contraseñas de las cuentas de prueba de la práctica.',
  ),
  Practica(
    id: 'bd_flutter',
    numero: 'BD',
    titulo: 'Reportes Firestore',
    descripcion:
        'Alta, consulta, actualización y borrado de reportes con transacciones.',
    stack: 'Flutter + Kotlin · Firestore',
    datos: 'Firebase reportes-movil-20261019 (app «bd_flutter»)',
    tipo: TipoPractica.flutter,
    construir: (_) => const bd_flutter.ReportesApp(),
  ),
  const Practica(
    id: 'bd_nativo',
    numero: 'BD',
    titulo: 'Reportes Firestore (nativo)',
    descripcion: 'La misma práctica de reportes hecha en Android nativo.',
    stack: 'Kotlin · Firestore',
    datos: 'Firebase reportes-movil-20261019 (app «bd_nativo»)',
    tipo: TipoPractica.nativa,
  ),
  const Practica(
    id: 'p09',
    numero: 'P9',
    titulo: 'Incidencias compartidas',
    descripcion:
        'Base de datos compartida en tiempo real, conflictos y bitácora entre equipos.',
    stack: 'Kotlin · Jetpack Compose · Firestore',
    datos: 'Firebase mesaayuda-p7 (app «p09»)',
    tipo: TipoPractica.nativa,
  ),
  const Practica(
    id: 'p10',
    numero: 'P10',
    titulo: 'Incidencias seguras',
    descripcion:
        'Cuentas con correo, propiedad por UID, asignaciones y pruebas de reglas.',
    stack: 'Kotlin · Compose · Firebase Auth · Firestore',
    datos: 'Firebase mesaayuda-p7 (app «p10»)',
    tipo: TipoPractica.nativa,
  ),
  Practica(
    id: 'eval2',
    numero: 'Eval. 2',
    titulo: 'MediConnect',
    descripcion:
        'Citas médicas con JWT, idempotencia y certificado TLS fijado.',
    stack: 'Flutter · Dio · API Node HTTPS',
    datos: 'API propia https://localhost:3443 (almacén seguro propio)',
    tipo: TipoPractica.flutter,
    construir: (_) => const eval2.MediConnectApp(),
    requisito:
        'Requiere su backend: node server.js (Evaluacion2/mediconnect/backend) y adb reverse tcp:3443 tcp:3443.',
  ),
];

import 'package:flutter/material.dart';

import 'bd_flutter/main.dart' as bd_flutter;
import 'eval2/main.dart' as eval2;
import 'examen1/main.dart' as examen1;
import 'p03_04/main.dart' as p03_04;
import 'p05/main.dart' as p05;
import 'p06/mobile_connect_app.dart' as p06;
import 'p07/main.dart' as p07;

/// Cómo se ejecuta la función dentro de CEOSMOS.
enum TipoPractica {
  /// App Flutter montada en una ruta de CEOSMOS con su propio MaterialApp.
  flutter,

  /// Actividad Android (Kotlin/Compose) incluida en el APK de CEOSMOS.
  nativa,
}

/// Sección de CEOSMOS donde vive cada función (también es el texto de «volver»).
enum Seccion {
  soporte('Soporte', '/soporte'),
  reportes('Reportes e incidencias', '/soporte/reportes'),
  equipos('Equipos', '/equipos'),
  perfil('Perfil', '/perfil');

  const Seccion(this.nombre, this.ruta);
  final String nombre;
  final String ruta;

  /// Texto del botón de regreso de la barra de la función.
  String get volver => this == Seccion.reportes ? 'Soporte' : nombre;
}

/// Una función de CEOSMOS que conserva su propia base de datos o servicio.
/// El id interno (p07, p09…) solo se usa en código y en las referencias académicas.
class Practica {
  const Practica({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.seccion,
    required this.icono,
    required this.ruta,
    required this.datos,
    required this.tipo,
    this.construir,
    this.requisito,
  });

  final String id;

  /// Nombre funcional visible.
  final String titulo;
  final String descripcion;
  final Seccion seccion;
  final IconData icono;

  /// Ruta visible de la función (p. ej. /soporte/tickets).
  final String ruta;

  /// Base de datos o servicio propio (nunca el de CEOSMOS).
  final String datos;
  final TipoPractica tipo;

  /// Widget raíz de la función (solo [TipoPractica.flutter]).
  final WidgetBuilder? construir;

  /// Condición externa para usarla (por ejemplo, un servidor local).
  final String? requisito;
}

final List<Practica> practicas = [
  Practica(
    id: 'p07',
    titulo: 'Tickets y chat interno',
    descripcion:
        'Crea tickets y da seguimiento por chat. El agente atiende sus asignados; el administrador asigna y gestiona.',
    seccion: Seccion.soporte,
    icono: Icons.support_agent_outlined,
    ruta: '/soporte/tickets',
    datos: 'Firebase practica7-8-941cb (app «practica7»)',
    tipo: TipoPractica.flutter,
    construir: (_) => const p07.Practica7Entrada(),
    requisito: 'Entra con tu cuenta de soporte (usuario, agente o administrador).',
  ),
  Practica(
    id: 'examen1',
    titulo: 'Incidencias sin conexión',
    descripcion: 'Registra fallas del equipo en este teléfono, aunque no haya red.',
    seccion: Seccion.soporte,
    icono: Icons.cloud_off_outlined,
    ruta: '/soporte/incidencias-locales',
    datos: 'SharedPreferences (clave examen1.incidencias)',
    tipo: TipoPractica.flutter,
    construir: (_) => const examen1.IncidenciasApp(),
  ),
  Practica(
    id: 'bd_flutter',
    titulo: 'Reportes compartidos',
    descripcion:
        'Registra, consulta, prioriza y elimina reportes sincronizados con la nube.',
    seccion: Seccion.reportes,
    icono: Icons.assignment_outlined,
    ruta: '/soporte/reportes/compartidos',
    datos: 'Firebase reportes-movil-20261019 (app «bd_flutter»)',
    tipo: TipoPractica.flutter,
    construir: (_) => const bd_flutter.ReportesApp(),
  ),
  const Practica(
    id: 'bd_nativo',
    titulo: 'Reportes compartidos (Android)',
    descripcion: 'Los mismos reportes, desde la versión nativa de Android.',
    seccion: Seccion.reportes,
    icono: Icons.android,
    ruta: '/soporte/reportes/android',
    datos: 'Firebase reportes-movil-20261019 (app «bd_nativo»)',
    tipo: TipoPractica.nativa,
  ),
  const Practica(
    id: 'p09',
    titulo: 'Incidencias en tiempo real',
    descripcion:
        'Incidencias compartidas entre equipos al instante, con bitácora y aviso de conflictos.',
    seccion: Seccion.reportes,
    icono: Icons.sync_alt,
    ruta: '/soporte/reportes/tiempo-real',
    datos: 'Firebase mesaayuda-p7 (app «p09»)',
    tipo: TipoPractica.nativa,
  ),
  const Practica(
    id: 'p10',
    titulo: 'Mis incidencias y acceso',
    descripcion:
        'Tus incidencias con tu cuenta: solo ves y editas las tuyas o las que te asignaron.',
    seccion: Seccion.reportes,
    icono: Icons.lock_person_outlined,
    ruta: '/soporte/reportes/mis-incidencias',
    datos: 'Firebase mesaayuda-p7 (app «p10»)',
    tipo: TipoPractica.nativa,
  ),
  Practica(
    id: 'p06',
    titulo: 'Mensajería entre equipos',
    descripcion:
        'Conversa con otro teléfono de la misma red Wi-Fi, sin pasar por internet.',
    seccion: Seccion.equipos,
    icono: Icons.forum_outlined,
    ruta: '/equipos/mensajeria',
    datos: 'Sin base de datos (mensajes en memoria)',
    tipo: TipoPractica.flutter,
    construir: (_) => const p06.MobileConnectApp(),
  ),
  Practica(
    id: 'p05',
    titulo: 'Seguridad de la cuenta',
    descripcion: 'Verifica tus credenciales con validación protegida del teléfono.',
    seccion: Seccion.perfil,
    icono: Icons.shield_outlined,
    ruta: '/perfil/seguridad',
    datos: 'Sin base de datos (validación local)',
    tipo: TipoPractica.flutter,
    construir: (_) => const p05.AccesoSeguroApp(),
  ),
  Practica(
    id: 'p03_04',
    titulo: 'Directorio de alumnos',
    descripcion: 'Alta, consulta, edición y baja de alumnos guardados en el teléfono.',
    seccion: Seccion.perfil,
    icono: Icons.contacts_outlined,
    ruta: '/perfil/directorio',
    datos: 'SQLite propio (p03_04_usuarios.db)',
    tipo: TipoPractica.flutter,
    construir: (_) => const p03_04.ConsultaWebApp(),
  ),
  Practica(
    id: 'eval2',
    titulo: 'Citas de bienestar',
    descripcion: 'Agenda y consulta citas con tu especialista de forma segura.',
    seccion: Seccion.perfil,
    icono: Icons.event_available_outlined,
    ruta: '/perfil/citas',
    datos: 'API propia https://localhost:3443 (almacén seguro propio)',
    tipo: TipoPractica.flutter,
    construir: (_) => const eval2.MediConnectApp(),
    requisito:
        'Requiere el servidor de citas en la computadora (node server.js) y adb reverse tcp:3443 tcp:3443.',
  ),
];

/// Funciones de una sección, en el orden del registro.
List<Practica> funcionesDe(Seccion s) =>
    practicas.where((p) => p.seccion == s).toList();

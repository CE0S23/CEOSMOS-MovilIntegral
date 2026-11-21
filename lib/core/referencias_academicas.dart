/// Referencias académicas de cada función de CEOSMOS (solo para revisión).
///
/// Es el ÚNICO lugar de la app donde se nombra la práctica de origen. Se
/// muestra con el botón ⓘ del encabezado de cada función.
///
/// ANTES DE LA ENTREGA FINAL: cambia [mostrarReferenciasAcademicas] a `false`
/// y todos los botones ⓘ desaparecen (Flutter y pantallas nativas).
library;

/// Interruptor global de los botones ⓘ «Referencia académica».
const bool mostrarReferenciasAcademicas = true;

class ReferenciaAcademica {
  const ReferenciaAcademica({required this.practica, required this.integracion});

  /// Nombre de la práctica y su tema.
  final String practica;

  /// Cómo se integró en CEOSMOS (una línea).
  final String integracion;

  /// Texto plano para las pantallas nativas (diálogo de Android).
  String get textoPlano =>
      'Referencia académica: $practica\n\nCómo se integró en CEOSMOS: $integracion';
}

/// Función (id interno del registro) → referencia académica.
const Map<String, ReferenciaAcademica> referenciasAcademicas = {
  'p03_04': ReferenciaAcademica(
    practica: 'Prácticas 3 y 4 · Consumo de servicio web y almacenamiento estructurado (SQLite/Floor)',
    integracion:
        'Directorio de alumnos en Perfil › Herramientas: alta, consulta, edición y baja en su propio SQLite, más la consulta del servicio web.',
  ),
  'p05': ReferenciaAcademica(
    practica: 'Práctica 5 · Código seguro (validación en Kotlin por canal de plataforma)',
    integracion:
        'Seguridad de la cuenta en Perfil: verificación de credenciales validada en la capa nativa, sin base de datos.',
  ),
  'p06': ReferenciaAcademica(
    practica: 'Práctica 6 · Interacción entre dispositivos (chat TCP por Wi-Fi)',
    integracion:
        'Mensajería entre equipos dentro de Equipos: dos teléfonos de la misma red conversan por sockets, mensajes en memoria.',
  ),
  'examen1': ReferenciaAcademica(
    practica: 'Examen 1 · Incidencias de soporte sin conexión (SharedPreferences)',
    integracion:
        'Incidencias sin conexión en Soporte: bitácora local del equipo para registrar fallas aunque no haya red.',
  ),
  'p07': ReferenciaAcademica(
    practica: 'Práctica 7 · Roles y mensajería (sistema de tickets con Firebase)',
    integracion:
        'Tickets y chat interno en Soporte: el usuario crea tickets, el agente atiende los asignados y el administrador asigna y gestiona.',
  ),
  'bd_flutter': ReferenciaAcademica(
    practica: 'Práctica de base de datos · Reportes en Firestore con transacciones (Flutter + Kotlin)',
    integracion:
        'Reportes compartidos en Soporte › Reportes e incidencias: alta, consulta, prioridad y baja sincronizadas con Firestore.',
  ),
  'bd_nativo': ReferenciaAcademica(
    practica: 'Práctica de base de datos · Reportes en Firestore (versión Android nativa)',
    integracion:
        'Reportes compartidos (Android) en Soporte › Reportes e incidencias: la misma colección operada desde Kotlin.',
  ),
  'p09': ReferenciaAcademica(
    practica: 'Práctica 9 · Base de datos compartida entre dispositivos (tiempo real, conflictos)',
    integracion:
        'Incidencias en tiempo real en Soporte › Reportes e incidencias: cambios simultáneos entre equipos con bitácora y resolución de conflictos.',
  ),
  'p10': ReferenciaAcademica(
    practica: 'Práctica 10 · Seguridad y control de acceso (reglas de Firestore, propiedad por UID)',
    integracion:
        'Mis incidencias y acceso en Soporte › Reportes e incidencias: cada cuenta solo ve y edita lo suyo o lo asignado; incluye la verificación de permisos.',
  ),
  'eval2': ReferenciaAcademica(
    practica: 'Evaluación 2 · MediConnect (citas con JWT, idempotencia y TLS fijado)',
    integracion:
        'Citas de bienestar en Perfil › Herramientas: agenda de citas contra un servidor seguro con certificado fijado.',
  ),
};

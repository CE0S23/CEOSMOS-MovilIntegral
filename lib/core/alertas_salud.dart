import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Actividades que informa el Reloj en el campo `act` (contrato con
/// `companion/.../Simulador.kt`, enum `Actividad`).
const actividadesReloj = {'reposo', 'durmiendo', 'caminando', 'trotando', 'corriendo'};

/// Nombre visible de cada actividad.
String nombreActividad(String? act) => switch (act) {
  'reposo' => 'Reposo',
  'durmiendo' => 'Durmiendo',
  'caminando' => 'Caminando',
  'trotando' => 'Trotando',
  'corriendo' => 'Corriendo',
  _ => 'Sin dato',
};

enum TipoAlerta {
  pulsoAlto('alto'),
  pulsoMuyAlto('muy_alto'),
  pulsoBajo('bajo');

  const TipoAlerta(this.clave);
  final String clave;
}

/// Alerta de salud generada a partir del pulso del Reloj (que es SIMULADO).
@immutable
class AlertaSalud {
  const AlertaSalud({
    required this.tipo,
    required this.hr,
    required this.actividad,
    required this.at,
  });
  final TipoAlerta tipo;
  final int hr;
  final String? actividad;
  final DateTime at;

  bool get urgente => tipo == TipoAlerta.pulsoMuyAlto;

  String get titulo => switch (tipo) {
    TipoAlerta.pulsoAlto => 'Pulso alto en ${nombreActividad(actividad).toLowerCase()}',
    TipoAlerta.pulsoMuyAlto => 'Pulso muy alto',
    TipoAlerta.pulsoBajo => 'Pulso bajo',
  };

  /// Texto corto (≤ 120 caracteres) para el Reloj, la TV y la notificación.
  String get texto => switch (tipo) {
    TipoAlerta.pulsoAlto => '$titulo: $hr bpm sostenido. Descansa y respira.',
    TipoAlerta.pulsoMuyAlto => '$titulo: $hr bpm. Detente y descansa.',
    TipoAlerta.pulsoBajo => '$titulo: $hr bpm sostenido. Revisa cómo te sientes.',
  };

  static const avisoSimulado = 'Pulso simulado del Reloj CEOSMOS: no es una medición médica.';
}

/// Reglas de alerta (orientativas, no clínicas):
///  - Pulso alto sostenido ~10 s en Reposo (>100), Durmiendo (>90) o Caminando (>130).
///  - Pulso muy alto (≥185) en cualquier actividad, sostenido 3 s.
///  - Pulso bajo (≤45) despierto, sostenido ~10 s.
///  - Trotar o correr con su pulso normal (hasta ~178) NO alerta.
/// Cada tipo tiene un enfriamiento de 60 s y hay un tope de alertas por sesión.
class MotorAlertas {
  MotorAlertas({
    this.sostenido = const Duration(seconds: 10),
    this.sostenidoMuyAlto = const Duration(seconds: 3),
    this.enfriamiento = const Duration(seconds: 60),
    this.topePorSesion = 5,
  });

  final Duration sostenido, sostenidoMuyAlto, enfriamiento;
  final int topePorSesion;

  static const muyAlto = 185;
  static const bajo = 45;
  static const altoPorActividad = {'reposo': 100, 'durmiendo': 90, 'caminando': 130};

  final _desde = <TipoAlerta, DateTime>{};
  final _ultima = <TipoAlerta, DateTime>{};
  int alertasEnSesion = 0;

  /// Empieza una sesión nueva: reinicia el tope y las condiciones sostenidas.
  void reiniciarSesion() {
    alertasEnSesion = 0;
    _desde.clear();
    _ultima.clear();
  }

  /// Condiciones que se cumplen con esta lectura (sin contar tiempo ni enfriamiento).
  @visibleForTesting
  static Set<TipoAlerta> condiciones(int hr, String? actividad) => {
    if (hr >= muyAlto) TipoAlerta.pulsoMuyAlto,
    if (altoPorActividad[actividad] case final umbral? when hr > umbral && hr < muyAlto) TipoAlerta.pulsoAlto,
    if (hr <= bajo && actividad != 'durmiendo') TipoAlerta.pulsoBajo,
  };

  /// Evalúa una lectura y devuelve la alerta que corresponde emitir (o null).
  AlertaSalud? evaluar(int hr, String? actividad, DateTime ahora) {
    final activas = condiciones(hr, actividad);
    for (final t in TipoAlerta.values) {
      if (!activas.contains(t)) _desde.remove(t);
    }
    // Prioridad: muy alto, bajo, alto.
    for (final t in const [TipoAlerta.pulsoMuyAlto, TipoAlerta.pulsoBajo, TipoAlerta.pulsoAlto]) {
      if (!activas.contains(t)) continue;
      final desde = _desde.putIfAbsent(t, () => ahora);
      final requerido = t == TipoAlerta.pulsoMuyAlto ? sostenidoMuyAlto : sostenido;
      if (ahora.difference(desde) < requerido) continue;
      final ultima = _ultima[t];
      if (ultima != null && ahora.difference(ultima) < enfriamiento) continue;
      if (alertasEnSesion >= topePorSesion) return null;
      _ultima[t] = ahora;
      alertasEnSesion++;
      return AlertaSalud(tipo: t, hr: hr, actividad: actividad, at: ahora);
    }
    return null;
  }
}

/// Muestra la alerta fuera de la app (notificación local de Android).
abstract interface class NotificadorAlertas {
  /// Pide el permiso de notificaciones si hace falta (Android 13+). true = concedido.
  Future<bool> pedirPermiso();
  Future<void> mostrar(AlertaSalud alerta);
}

/// Sin notificaciones del sistema (pruebas, web y escritorio): solo el aviso interno.
class NotificadorNulo implements NotificadorAlertas {
  const NotificadorNulo();
  @override
  Future<bool> pedirPermiso() async => false;
  @override
  Future<void> mostrar(AlertaSalud alerta) async {}
}

/// Notificación local de Android por el canal nativo `ceosmos/alertas` (canal del sistema
/// «Alertas de salud»; `MainActivity.kt` pide POST_NOTIFICATIONS en Android 13+).
class NotificadorAndroid implements NotificadorAlertas {
  static const _canal = MethodChannel('ceosmos/alertas');

  @override
  Future<bool> pedirPermiso() async {
    try {
      return await _canal.invokeMethod<bool>('pedirPermiso') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  @override
  Future<void> mostrar(AlertaSalud a) async {
    try {
      await _canal.invokeMethod<void>('mostrar', {
        'titulo': a.titulo,
        'texto': '${a.texto} ${AlertaSalud.avisoSimulado}',
        'tipo': a.tipo.clave,
      });
    } on PlatformException catch (e) {
      debugPrint('Alertas: notificación no mostrada (${e.code})');
    } on MissingPluginException {
      // Sin canal (pruebas): basta el aviso dentro de la app.
    }
  }
}

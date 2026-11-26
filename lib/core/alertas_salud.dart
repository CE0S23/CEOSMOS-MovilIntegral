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
///
/// 1.4.0 (corrección de la alerta intermitente):
///  - Histéresis: una condición empieza al cruzar el umbral y solo termina cuando el pulso
///    se aleja [margen] bpm (o sale del margen más de [tolerancia]); el ruido de ±1 bpm
///    justo en el umbral ya no reinicia el conteo de «sostenido».
///  - Enfriamiento de 60 s POR TIPO y una sola alerta por episodio (con un recordatorio a
///    los 5 min si sigue). Ya no hay un tope compartido por sesión: antes, tras 5 alertas
///    de cualquier tipo, ninguna otra llegaba hasta iniciar otra sesión.
///  - Pulso alto ya no se corta al pasar a «muy alto»; si acaba de avisarse «muy alto» no
///    se repite como «alto».
class MotorAlertas {
  MotorAlertas({
    this.sostenido = const Duration(seconds: 10),
    this.sostenidoMuyAlto = const Duration(seconds: 3),
    this.enfriamiento = const Duration(seconds: 60),
    this.recordatorio = const Duration(minutes: 5),
    this.tolerancia = const Duration(seconds: 2),
  });

  final Duration sostenido, sostenidoMuyAlto, enfriamiento, recordatorio, tolerancia;

  static const muyAlto = 185;
  static const bajo = 45;
  static const margen = 3;
  static const altoPorActividad = {'reposo': 100, 'durmiendo': 90, 'caminando': 130};

  final _desde = <TipoAlerta, DateTime>{};
  final _fueraDesde = <TipoAlerta, DateTime>{};
  final _ultima = <TipoAlerta, DateTime>{};
  final _avisadaEnEpisodio = <TipoAlerta>{};

  /// Alertas emitidas desde [reiniciarSesion] (informativo; no limita).
  int alertasEnSesion = 0;

  /// Empieza una sesión nueva: reinicia el conteo y las condiciones sostenidas.
  void reiniciarSesion() {
    alertasEnSesion = 0;
    _desde.clear();
    _fueraDesde.clear();
    _ultima.clear();
    _avisadaEnEpisodio.clear();
  }

  /// Condiciones que se cumplen con esta lectura (sin contar tiempo ni enfriamiento).
  @visibleForTesting
  static Set<TipoAlerta> condiciones(int hr, String? actividad) => {
    if (hr >= muyAlto) TipoAlerta.pulsoMuyAlto,
    if (altoPorActividad[actividad] case final umbral? when hr > umbral && hr < muyAlto) TipoAlerta.pulsoAlto,
    if (hr <= bajo && actividad != 'durmiendo') TipoAlerta.pulsoBajo,
  };

  /// Banda de histéresis: la condición sigue «en curso» mientras se cumple esto.
  static bool _enBanda(TipoAlerta t, int hr, String? actividad) => switch (t) {
    TipoAlerta.pulsoMuyAlto => hr >= muyAlto - margen,
    TipoAlerta.pulsoAlto => switch (altoPorActividad[actividad]) {
      final umbral? => hr > umbral - margen,
      null => false,
    },
    TipoAlerta.pulsoBajo => hr <= bajo + margen && actividad != 'durmiendo',
  };

  void _terminar(TipoAlerta t) {
    _desde.remove(t);
    _fueraDesde.remove(t);
    _avisadaEnEpisodio.remove(t);
  }

  /// Evalúa una lectura y devuelve la alerta que corresponde emitir (o null).
  AlertaSalud? evaluar(int hr, String? actividad, DateTime ahora) {
    final activas = condiciones(hr, actividad);
    // El pulso alto sigue en curso aunque suba a «muy alto».
    if (activas.contains(TipoAlerta.pulsoMuyAlto) && altoPorActividad.containsKey(actividad)) {
      activas.add(TipoAlerta.pulsoAlto);
    }
    for (final t in TipoAlerta.values) {
      if (activas.contains(t)) {
        _desde.putIfAbsent(t, () => ahora);
        _fueraDesde.remove(t);
      } else if (_desde.containsKey(t)) {
        if (_enBanda(t, hr, actividad)) {
          _fueraDesde.remove(t); // dentro del margen: el episodio continúa
        } else {
          final fuera = _fueraDesde.putIfAbsent(t, () => ahora);
          if (ahora.difference(fuera) > tolerancia) _terminar(t);
        }
      }
    }
    // Prioridad: muy alto, bajo, alto.
    for (final t in const [TipoAlerta.pulsoMuyAlto, TipoAlerta.pulsoBajo, TipoAlerta.pulsoAlto]) {
      final desde = _desde[t];
      if (desde == null || _fueraDesde.containsKey(t)) continue;
      final requerido = t == TipoAlerta.pulsoMuyAlto ? sostenidoMuyAlto : sostenido;
      if (ahora.difference(desde) < requerido) continue;
      final ultima = _ultima[t];
      if (ultima != null && ahora.difference(ultima) < enfriamiento) continue;
      if (_avisadaEnEpisodio.contains(t) && ultima != null && ahora.difference(ultima) < recordatorio) continue;
      if (t == TipoAlerta.pulsoAlto) {
        final muy = _ultima[TipoAlerta.pulsoMuyAlto];
        if (muy != null && ahora.difference(muy) < enfriamiento) continue;
      }
      _ultima[t] = ahora;
      _avisadaEnEpisodio.add(t);
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

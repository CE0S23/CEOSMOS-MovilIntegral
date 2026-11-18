// Protocolo BLE de CEOSMOS con sus dispositivos compañeros (Reloj y TV).
//
// CEOSMOS (Samsung S24) es el CENTRAL; las apps «CEOSMOS Reloj» y «CEOSMOS TV»
// (carpeta `companion/`) son PERIFÉRICOS con un servidor GATT propio.
// Los mismos UUID están en `companion/app/src/main/java/com/ceosmos/companion/ble/Protocolo.kt`.
//
// Servicio Reloj  6c3e1000-9b1a-4c5e-8a10-ce05a0b1e000
//   AUTH   6c3e1001-…  read: reto (16 bytes aleatorios) · write: HMAC-SHA256(PIN, reto‖"reloj")
//   A_DISP 6c3e1002-…  write (con respuesta): JSON de CEOSMOS → reloj (requiere AUTH)
//   DE_DISP 6c3e1003-… notify: JSON del reloj → CEOSMOS (CCCD solo tras AUTH)
// Servicio TV     6c3e2000-9b1a-4c5e-8a10-ce05a0b1e000 (características 6c3e2001/2002/2003)
//
// Seguridad: el periférico muestra un PIN de 6 dígitos. CEOSMOS nunca lo envía
// por el aire: lee un reto aleatorio y responde con su HMAC. Hasta autenticarse, el
// periférico rechaza escrituras y suscripciones (GATT_INSUFFICIENT_AUTHORIZATION),
// y tras 3 intentos fallidos desconecta y bloquea esa dirección 60 s.
import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Base común de los UUID (los 4 primeros dígitos hexadecimales cambian).
const _sufijoUuid = '-9b1a-4c5e-8a10-ce05a0b1e000';

/// Identificador de fabricante de prueba (0xFFFF, reservado para pruebas por el
/// Bluetooth SIG) en el que el periférico anuncia su id estable de 4 bytes.
const fabricanteCeosmos = 0xFFFF;

/// Tamaño máximo de un mensaje JSON en cualquiera de los dos sentidos.
const maxBytesMensaje = 180;

enum RolBle {
  reloj('reloj', 'WEARABLE', 0x01, 'Reloj'),
  tv('tv', 'TV', 0x02, 'TV');

  const RolBle(this.etiqueta, this.tipoApi, this.codigo, this.nombre);

  /// Texto que se mezcla en el HMAC (una respuesta del reloj no sirve para la TV).
  final String etiqueta;

  /// Tipo con el que se guarda en `/devices` de la API.
  final String tipoApi;

  /// Primer byte de los datos de fabricante del anuncio.
  final int codigo;
  final String nombre;

  String get _p => this == RolBle.reloj ? '6c3e1' : '6c3e2';
  String get servicio => '${_p}000$_sufijoUuid';
  String get auth => '${_p}001$_sufijoUuid';
  String get aDispositivo => '${_p}002$_sufijoUuid';
  String get deDispositivo => '${_p}003$_sufijoUuid';

  static RolBle? deTipoApi(String tipo) {
    for (final r in values) {
      if (r.tipoApi == tipo) return r;
    }
    return null;
  }
}

/// PIN de 6 dígitos que muestra el periférico.
bool pinValido(String pin) => RegExp(r'^\d{6}$').hasMatch(pin);

/// Respuesta al reto de autenticación: HMAC-SHA256(PIN, reto ‖ etiqueta del rol).
List<int> respuestaReto(String pin, List<int> reto, RolBle rol) {
  if (!pinValido(pin)) throw ArgumentError('PIN inválido');
  if (reto.length != 16) throw ArgumentError('Reto inválido');
  return Hmac(sha256, utf8.encode(pin))
      .convert([...reto, ...utf8.encode(rol.etiqueta)])
      .bytes;
}

/// Id estable del periférico (4 bytes de los datos de fabricante) en hexadecimal.
String? leerIdCompanero(Map<int, List<int>> datosFabricante, RolBle rol) {
  final d = datosFabricante[fabricanteCeosmos];
  if (d == null || d.length != 5 || d[0] != rol.codigo) return null;
  return d.sublist(1).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

/// La API guarda la dirección del dispositivo en formato MAC. Android rota la MAC
/// del periférico por privacidad, así que se guarda el id estable del compañero
/// con forma de MAC (`CE:05:` + 4 bytes); la reconexión busca ese id en el anuncio.
String direccionApi(String idCompanero) {
  final b = idCompanero.toUpperCase();
  return 'CE:05:${b.substring(0, 2)}:${b.substring(2, 4)}:${b.substring(4, 6)}:${b.substring(6, 8)}';
}

String? idDesdeDireccion(String direccion) {
  final m = RegExp(r'^CE:05:([0-9A-F]{2}):([0-9A-F]{2}):([0-9A-F]{2}):([0-9A-F]{2})$')
      .firstMatch(direccion.toUpperCase());
  if (m == null) return null;
  return [for (var i = 1; i <= 4; i++) m.group(i)!].join().toLowerCase();
}

// -----------------------------------------------------------------------------
// Mensajes del periférico → CEOSMOS
// -----------------------------------------------------------------------------

sealed class MensajeEntrante {
  const MensajeEntrante();
}

/// Lectura simulada del reloj (frecuencia cardiaca y pasos).
class LecturaReloj extends MensajeEntrante {
  const LecturaReloj(this.hr, this.pasos);
  final int hr;
  final int? pasos;
}

/// Comando del reloj (botón de acción) o de la TV (control remoto / D-pad).
class ComandoRemoto extends MensajeEntrante {
  const ComandoRemoto(this.comando);
  final String comando;
}

class SaludoRemoto extends MensajeEntrante {
  const SaludoRemoto(this.nombre);
  final String nombre;
}

const comandosReloj = {'toggle', 'stop'};
const comandosTv = {'toggle', 'stop', 'next', 'prev'};

/// Decodifica y valida un mensaje recibido. Devuelve null si no cumple el
/// protocolo (tamaño, JSON, tipo, rangos): un mensaje inválido se descarta.
MensajeEntrante? decodificar(List<int> bytes, RolBle rol) {
  if (bytes.isEmpty || bytes.length > maxBytesMensaje) return null;
  final Object? json;
  try {
    json = jsonDecode(utf8.decode(bytes));
  } on FormatException {
    return null;
  }
  if (json is! Map<String, dynamic>) return null;
  switch (json['t']) {
    case 'hello':
      final n = json['name'];
      if (n is! String || n.trim().isEmpty || n.length > 30) return null;
      return SaludoRemoto(n.trim());
    case 'hr' when rol == RolBle.reloj:
      final hr = json['hr'];
      final pasos = json['steps'];
      if (hr is! int || hr < 30 || hr > 230) return null;
      if (pasos != null && (pasos is! int || pasos < 0 || pasos > 1000000)) {
        return null;
      }
      return LecturaReloj(hr, pasos as int?);
    case 'btn' when rol == RolBle.reloj:
      final a = json['a'];
      return a is String && comandosReloj.contains(a) ? ComandoRemoto(a) : null;
    case 'cmd' when rol == RolBle.tv:
      final c = json['c'];
      return c is String && comandosTv.contains(c) ? ComandoRemoto(c) : null;
  }
  return null;
}

// -----------------------------------------------------------------------------
// Mensajes CEOSMOS → periférico
// -----------------------------------------------------------------------------

/// Codifica un mensaje y garantiza que quepa en [maxBytesMensaje] recortando
/// el texto libre (`msg`, `title`, `user`) si hace falta.
List<int> codificar(Map<String, Object?> mensaje) {
  var m = Map<String, Object?>.of(mensaje);
  var bytes = utf8.encode(jsonEncode(m));
  for (final campo in ['msg', 'title', 'user']) {
    while (bytes.length > maxBytesMensaje && m[campo] is String && (m[campo] as String).isNotEmpty) {
      final s = m[campo] as String;
      final exceso = bytes.length - maxBytesMensaje;
      // El exceso está en bytes y un carácter UTF-8 ocupa de 1 a 4: se recorta poco a poco.
      final corte = (exceso ~/ 4).clamp(1, s.length);
      m[campo] = s.substring(0, s.length - corte);
      bytes = utf8.encode(jsonEncode(m));
    }
  }
  if (bytes.length > maxBytesMensaje) throw ArgumentError('Mensaje demasiado grande');
  return bytes;
}

/// Estado de la sesión de enfoque que se proyecta en el reloj y la TV.
class EstadoSesionBle {
  const EstadoSesionBle({
    required this.estado,
    this.titulo = '',
    this.modo = '',
    this.restante = 0,
    this.total = 0,
    this.usuario = '',
  });

  /// `idle`, `running` o `paused`.
  final String estado;
  final String titulo, modo, usuario;
  final int restante, total;

  static const inactivo = EstadoSesionBle(estado: 'idle');

  Map<String, Object?> aMensaje({int? hr}) => {
        't': 'session',
        'state': estado,
        'title': titulo,
        'mode': modo,
        'rem': restante,
        'tot': total,
        'hr': ?hr,
        'user': usuario,
      };
}

// White Box del protocolo BLE: UUID fijos, HMAC del reto, validación de mensajes
// (ramas de `decodificar`) y recorte de mensajes salientes (valores límite).
import 'dart:convert';

import 'package:ceosmos_movil_integral/core/ble/ble_protocolo.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

List<int> j(Object o) => utf8.encode(jsonEncode(o));

void main() {
  group('UUID', () {
    test('fijos, distintos por rol y con la base común', () {
      expect(RolBle.reloj.servicio, '6c3e1000-9b1a-4c5e-8a10-ce05a0b1e000');
      expect(RolBle.reloj.auth, '6c3e1001-9b1a-4c5e-8a10-ce05a0b1e000');
      expect(RolBle.reloj.aDispositivo, '6c3e1002-9b1a-4c5e-8a10-ce05a0b1e000');
      expect(RolBle.reloj.deDispositivo, '6c3e1003-9b1a-4c5e-8a10-ce05a0b1e000');
      expect(RolBle.tv.servicio, '6c3e2000-9b1a-4c5e-8a10-ce05a0b1e000');
      final todos = {for (final r in RolBle.values) ...[r.servicio, r.auth, r.aDispositivo, r.deDispositivo]};
      expect(todos, hasLength(8));
    });
    test('tipo de la API', () {
      expect(RolBle.deTipoApi('WEARABLE'), RolBle.reloj);
      expect(RolBle.deTipoApi('TV'), RolBle.tv);
      expect(RolBle.deTipoApi('OTRO'), isNull);
    });
  });

  group('Autenticación por reto', () {
    final reto = List.generate(16, (i) => i);
    test('HMAC-SHA256(PIN, reto‖rol) y distinto por rol', () {
      final esperado = Hmac(sha256, utf8.encode('123456')).convert([...reto, ...utf8.encode('reloj')]).bytes;
      expect(respuestaReto('123456', reto, RolBle.reloj), esperado);
      expect(respuestaReto('123456', reto, RolBle.tv), isNot(esperado));
      expect(respuestaReto('654321', reto, RolBle.reloj), isNot(esperado));
    });
    test('PIN y reto inválidos lanzan error (valores límite)', () {
      for (final pin in ['', '12345', '1234567', '12a456', ' 12345']) {
        expect(pinValido(pin), isFalse, reason: pin);
        expect(() => respuestaReto(pin, reto, RolBle.reloj), throwsArgumentError);
      }
      expect(pinValido('000000'), isTrue);
      expect(() => respuestaReto('123456', reto.sublist(1), RolBle.reloj), throwsArgumentError);
    });
  });

  group('Id del compañero', () {
    test('se lee del anuncio solo si coincide el rol y el tamaño', () {
      expect(leerIdCompanero({0xFFFF: [1, 0xAB, 0x01, 0x02, 0xFF]}, RolBle.reloj), 'ab0102ff');
      expect(leerIdCompanero({0xFFFF: [2, 0xAB, 0x01, 0x02, 0xFF]}, RolBle.reloj), isNull);
      expect(leerIdCompanero({0xFFFF: [1, 0xAB]}, RolBle.reloj), isNull);
      expect(leerIdCompanero({0x004C: [1, 0xAB, 1, 2, 3]}, RolBle.reloj), isNull);
    });
    test('dirección para la API ida y vuelta', () {
      expect(direccionApi('ab0102ff'), 'CE:05:AB:01:02:FF');
      expect(idDesdeDireccion('CE:05:AB:01:02:FF'), 'ab0102ff');
      expect(idDesdeDireccion('192.168.1.2:5050'), isNull);
      expect(idDesdeDireccion('AA:05:AB:01:02:FF'), isNull);
    });
  });

  group('decodificar (entradas del periférico)', () {
    test('lecturas del reloj válidas y límites de hr', () {
      final l = decodificar(j({'t': 'hr', 'hr': 72, 'steps': 1240}), RolBle.reloj) as LecturaReloj;
      expect((l.hr, l.pasos), (72, 1240));
      expect(decodificar(j({'t': 'hr', 'hr': 30}), RolBle.reloj), isA<LecturaReloj>());
      expect(decodificar(j({'t': 'hr', 'hr': 230}), RolBle.reloj), isA<LecturaReloj>());
      for (final hr in [29, 231, '72', 72.5, null]) {
        expect(decodificar(j({'t': 'hr', 'hr': hr}), RolBle.reloj), isNull, reason: '$hr');
      }
      for (final pasos in [-1, 1000001, '10']) {
        expect(decodificar(j({'t': 'hr', 'hr': 70, 'steps': pasos}), RolBle.reloj), isNull);
      }
    });
    test('comandos permitidos por rol', () {
      expect((decodificar(j({'t': 'btn', 'a': 'toggle'}), RolBle.reloj) as ComandoRemoto).comando, 'toggle');
      expect(decodificar(j({'t': 'btn', 'a': 'next'}), RolBle.reloj), isNull);
      expect((decodificar(j({'t': 'cmd', 'c': 'next'}), RolBle.tv) as ComandoRemoto).comando, 'next');
      expect(decodificar(j({'t': 'cmd', 'c': 'rm -rf'}), RolBle.tv), isNull);
      // Un reloj no puede enviar comandos de TV ni la TV lecturas.
      expect(decodificar(j({'t': 'cmd', 'c': 'stop'}), RolBle.reloj), isNull);
      expect(decodificar(j({'t': 'hr', 'hr': 80}), RolBle.tv), isNull);
    });
    test('saludo y entradas basura, vacías o enormes', () {
      expect((decodificar(j({'t': 'hello', 'name': ' Reloj '}), RolBle.reloj) as SaludoRemoto).nombre, 'Reloj');
      expect(decodificar(j({'t': 'hello', 'name': 'x' * 31}), RolBle.tv), isNull);
      expect(decodificar(j({'t': 'hello', 'name': '  '}), RolBle.tv), isNull);
      expect(decodificar([], RolBle.tv), isNull);
      expect(decodificar(List.filled(maxBytesMensaje + 1, 0x20), RolBle.tv), isNull);
      expect(decodificar(utf8.encode('{no json'), RolBle.tv), isNull);
      expect(decodificar([0xFF, 0xFE], RolBle.tv), isNull);
      expect(decodificar(j([1, 2]), RolBle.tv), isNull);
      expect(decodificar(j({'t': 'otro'}), RolBle.tv), isNull);
    });
  });

  group('codificar (salidas de CEOSMOS)', () {
    test('mensaje corto intacto', () {
      expect(jsonDecode(utf8.decode(codificar({'t': 'notif', 'msg': 'Hola'}))), {'t': 'notif', 'msg': 'Hola'});
    });
    test('texto largo se recorta hasta caber', () {
      final b = codificar({'t': 'notif', 'msg': 'á' * 400});
      expect(b.length, lessThanOrEqualTo(maxBytesMensaje));
      expect((jsonDecode(utf8.decode(b)) as Map)['msg'], startsWith('á'));
    });
    test('sin campo recortable y enorme → error', () {
      expect(() => codificar({'t': 'x', 'data': 'z' * 400}), throwsArgumentError);
    });
    test('estado de sesión', () {
      const s = EstadoSesionBle(estado: 'running', titulo: 'Órbita', modo: 'focus', restante: 60, total: 300, usuario: 'ana');
      expect(s.aMensaje(hr: 70), containsPair('hr', 70));
      expect(s.aMensaje().containsKey('hr'), isFalse);
      expect(EstadoSesionBle.inactivo.aMensaje()['state'], 'idle');
    });
  });
}

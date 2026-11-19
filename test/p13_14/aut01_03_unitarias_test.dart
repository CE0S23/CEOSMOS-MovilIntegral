// P13-14 · Pruebas UNITARIAS de la lógica de negocio de los 3 componentes críticos:
//   1. Acceso (inicio de sesión / registro): validadores de AuthRepository.
//   2. Comunicación: protocolo BLE reto + HMAC y traducción de errores de la API.
//   3. Persistencia P4: validadores del formulario de alumnos (antes acoplados a la UI).
// Cada grupo cubre entrada válida, vacía/nula, fuera de rango, resultado esperado y
// manejo de excepciones. Sin red, sin Firebase y sin producción.
import 'dart:convert';

import 'package:ceosmos_movil_integral/core/ble/ble_protocolo.dart';
import 'package:ceosmos_movil_integral/core/config.dart';
import 'package:ceosmos_movil_integral/data/api_client.dart';
import 'package:ceosmos_movil_integral/data/auth_repository.dart';
import 'package:ceosmos_movil_integral/practicas/p03_04/usuarios/usuarios_page.dart';
import 'package:flutter_test/flutter_test.dart';

List<int> _b(Object json) => utf8.encode(jsonEncode(json));
String _hex(List<int> b) => b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();

void main() {
  // ---------------------------------------------------------------------------
  group('AUT-01 · Entrada válida y entrada vacía / nula', () {
    test('Acceso: correo, contraseña, usuario y código válidos → sin error', () {
      expect(AuthRepository.validarCorreo('  Ana@Ceosmos.mx '), isNull);
      expect(AuthRepository.validarContrasenaNueva('Orbita#2026'), isNull);
      expect(AuthRepository.validarUsuario('ana'), isNull);
      expect(AuthRepository.validarCodigoVerificacion(' a1b2c3 '), isNull);
      expect(AuthRepository.validarTokenRestablecer('0123456789abcdef'), isNull);
      expect(AuthRepository.validarContrasenaLogin('cualquiera'), isNull);
    });

    test('Acceso: vacío o null → mensaje de campo obligatorio (nunca excepción)', () {
      for (final v in [null, '', '   ']) {
        expect(AuthRepository.validarCorreo(v), 'Escribe tu correo.');
        expect(AuthRepository.validarUsuario(v), 'Entre 3 y 30 caracteres.');
        expect(AuthRepository.validarCodigoVerificacion(v), 'El código tiene 6 caracteres (0-9, A-F).');
        expect(AuthRepository.validarTokenRestablecer(v), 'Pega el código completo del enlace.');
      }
      expect(AuthRepository.validarContrasenaLogin(null), 'Escribe tu contraseña.');
      expect(AuthRepository.validarContrasenaLogin(''), 'Escribe tu contraseña.');
      expect(AuthRepository.validarContrasenaNueva(null), 'Mínimo 8 caracteres.');
    });

    test('P4: alumno válido y campos vacíos / nulos', () {
      expect(validarEdadUsuario('21'), isNull);
      expect(validarCorreoUsuario('alumno@uni.mx'), isNull);
      expect(validarObligatorio('Ingresa el nombre.')('Ana'), isNull);
      for (final v in [null, '', '  ']) {
        expect(validarEdadUsuario(v), 'Ingresa una edad entera entre 1 y 120.');
        expect(validarCorreoUsuario(v), 'Ingresa el correo.');
        expect(validarObligatorio('Ingresa el nombre.')(v), 'Ingresa el nombre.');
      }
    });

    test('BLE: mensaje vacío del periférico se descarta (null)', () {
      expect(decodificar(const [], RolBle.reloj), isNull);
      expect(decodificar(_b({}), RolBle.tv), isNull);
      expect(decodificar(_b({'t': 'hello', 'name': '  '}), RolBle.tv), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  group('AUT-02 · Valores fuera de rango y resultado esperado', () {
    test('Contraseña: 7 y 73 caracteres fuera de rango; 8 y 72 dentro', () {
      expect(AuthRepository.validarContrasenaNueva('Ab1#567'), 'Mínimo 8 caracteres.');
      expect(AuthRepository.validarContrasenaNueva('Ab1#5678'), isNull);
      expect(AuthRepository.validarContrasenaNueva('Ab1#${'x' * 68}'), isNull); // 72
      expect(AuthRepository.validarContrasenaNueva('Ab1#${'x' * 69}'), 'Máximo 72 caracteres.'); // 73
    });

    test('Usuario 2/31 y código de 5/7 o no hexadecimal → rechazados', () {
      expect(AuthRepository.validarUsuario('ab'), isNotNull);
      expect(AuthRepository.validarUsuario('a' * 31), isNotNull);
      expect(AuthRepository.validarUsuario('a' * 30), isNull);
      for (final c in ['A1B2C', 'A1B2C3D', 'G1B2C3', 'a1 b2c']) {
        expect(AuthRepository.validarCodigoVerificacion(c), isNotNull, reason: c);
      }
    });

    test('P4: edad 0, 121, -5, 2.5 y texto fuera de rango; 1 y 120 en el límite', () {
      for (final e in ['0', '121', '-5', '2.5', 'veinte']) {
        expect(validarEdadUsuario(e), isNotNull, reason: e);
      }
      expect(validarEdadUsuario('1'), isNull);
      expect(validarEdadUsuario(' 120 '), isNull);
      expect(validarCorreoUsuario('${'a' * 115}@uni.mx'), 'Ingresa un correo válido.'); // > 120
      expect(validarCorreoUsuario('alumno@uni'), 'Ingresa un correo válido.');
    });

    test('BLE: pulso 29/231 y pasos negativos fuera de rango; 30/230 aceptados', () {
      expect(decodificar(_b({'t': 'hr', 'hr': 29}), RolBle.reloj), isNull);
      expect(decodificar(_b({'t': 'hr', 'hr': 231}), RolBle.reloj), isNull);
      expect(decodificar(_b({'t': 'hr', 'hr': 72, 'steps': -1}), RolBle.reloj), isNull);
      final min = decodificar(_b({'t': 'hr', 'hr': 30}), RolBle.reloj) as LecturaReloj;
      final max = decodificar(_b({'t': 'hr', 'hr': 230, 'steps': 1240}), RolBle.reloj) as LecturaReloj;
      expect((min.hr, min.pasos), (30, null));
      expect((max.hr, max.pasos), (230, 1240));
      // Un comando válido de la TV no es válido para el reloj (rol fuera de su dominio).
      expect(decodificar(_b({'t': 'cmd', 'c': 'next'}), RolBle.reloj), isNull);
      expect((decodificar(_b({'t': 'cmd', 'c': 'next'}), RolBle.tv) as ComandoRemoto).comando, 'next');
    });

    test('HMAC del reto: mismo vector que el periférico Kotlin (resultado esperado)', () {
      final reto = List<int>.generate(16, (i) => i);
      // Vectores fijos de companion/.../ProtocoloTest.kt: si Dart y Kotlin divergen, ninguno conecta.
      expect(_hex(respuestaReto('123456', reto, RolBle.reloj)),
          '40f2513526965e935fcefb9697aff28b25ae0b6a218786db3c0dc2502d6bb336');
      expect(_hex(respuestaReto('123456', reto, RolBle.tv)),
          '847d88dd481248921c75867d220a9ec0d2924909b21a52386bc05ac5bbc152bf');
    });

    test('Mensaje de sesión demasiado largo se recorta hasta 180 bytes', () {
      final bytes = codificar({'t': 'session', 'title': 'Ñ' * 300, 'user': 'ana'});
      expect(bytes.length, lessThanOrEqualTo(maxBytesMensaje));
      expect((jsonDecode(utf8.decode(bytes)) as Map)['user'], 'ana');
    });

    test('Las pruebas nunca apuntan a producción: sin --dart-define la API es local', () {
      expect(AppConfig.apiBaseUrl, anyOf(startsWith('http://localhost'), startsWith('http://10.0.2.2')));
      expect(AppConfig.apiBaseUrl, isNot(contains('vercel.app')));
    });
  });

  // ---------------------------------------------------------------------------
  group('AUT-03 · Manejo de excepciones', () {
    test('PIN o reto inválidos lanzan ArgumentError (no se calcula un HMAC débil)', () {
      final reto = List<int>.filled(16, 7);
      for (final pin in ['', '12345', '1234567', '12a456']) {
        expect(() => respuestaReto(pin, reto, RolBle.tv), throwsArgumentError, reason: pin);
      }
      expect(() => respuestaReto('123456', List.filled(15, 0), RolBle.tv), throwsArgumentError);
      expect(() => respuestaReto('123456', List.filled(17, 0), RolBle.tv), throwsArgumentError);
    });

    test('Bytes que no son UTF-8 / JSON o exceden 180 bytes no lanzan: se descartan', () {
      expect(decodificar(const [0xff, 0xfe, 0x00], RolBle.reloj), isNull);
      expect(decodificar(utf8.encode('{no json'), RolBle.reloj), isNull);
      expect(decodificar(utf8.encode('[1,2]'), RolBle.reloj), isNull);
      expect(decodificar(List.filled(maxBytesMensaje + 1, 0x20), RolBle.tv), isNull);
    });

    test('Mensaje saliente imposible de recortar → ArgumentError controlado', () {
      expect(() => codificar({'t': 'x', 'datos': 'z' * 400}), throwsArgumentError);
    });

    test('Errores HTTP del backend se traducen a un mensaje seguro (sin detalles internos)', () {
      expect(traducirError(401, {'message': 'Invalid credentials'}), 'Correo o contraseña incorrectos.');
      expect(traducirError(401, null), 'Tu sesión expiró. Vuelve a iniciar sesión.');
      expect(traducirError(404, {'message': 'Device not found'}), 'No se encontró el recurso solicitado.');
      expect(traducirError(500, {'message': 'QueryFailedError: relation users …'}),
          'El servidor de CEOSMOS tuvo un problema. Intenta más tarde.');
      expect(traducirError(429, {'message': 'ThrottlerException: Too Many Requests'}),
          'Demasiados intentos. Espera un momento e inténtalo de nuevo.');
      const e = ApiException('x', statusCode: 401);
      expect(e.unauthorized, isTrue);
      expect(e.toString(), 'x');
    });
  });
}

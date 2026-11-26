// Práctica 11 · Fase 2 · Método de VALIDACIÓN
// WearableLectura.parse (lib/core/wearable.dart:16) y su llamador
// WearableClientImpl._alRecibir (lib/core/wearable_io.dart:72).
//
// Grafo de flujo de parse (nodos = sentencias/condiciones atómicas):
//   N1 hr, steps = json[...]
//   C1 hr is! num ──V──► R0 return null
//   C2 hr < 30    ──V──► R0
//   C3 hr > 230   ──V──► R0
//   C4 steps != null ──F──► N5 return WearableLectura
//   C5 steps is! num ──V──► R0
//   C6 steps < 0     ──V──► R0 / F ──► N5
// V(G) = 6 condiciones atómicas + 1 = 7 caminos independientes (CB1..CB7).
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ceosmos_movil_integral/core/wearable.dart';
import 'package:ceosmos_movil_integral/data/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

final _t = DateTime(2026, 11, 11, 12);
WearableLectura? _p(Map<String, dynamic> json) => WearableLectura.parse(json, _t);

void main() {
  group('WB-01/02/03 parse: caminos independientes (cobertura de condiciones)', () {
    // Cada caso fija el valor de verdad de C1..C6 (V = verdadero, F = falso, - = no evaluada).
    test('CB1  C1=V: hr ausente → null', () => expect(_p({'steps': 10}), isNull));
    test('CB1b C1=V: hr de tipo texto → null', () => expect(_p({'hr': '72'}), isNull));
    test('CB2  C1=F C2=V: hr=29 → null', () => expect(_p({'hr': 29}), isNull));
    test('CB3  C1=F C2=F C3=V: hr=231 → null', () => expect(_p({'hr': 231}), isNull));
    test('CB4  C3=F C4=F: sin steps → lectura con steps null', () {
      final l = _p({'hr': 72})!;
      expect((l.heartRate, l.steps, l.at), (72, null, _t));
    });
    test('CB5  C4=V C5=V: steps no numérico → null', () {
      expect(_p({'hr': 72, 'steps': 'mil'}), isNull);
    });
    test('CB6  C4=V C5=F C6=V: steps=-1 → null', () {
      expect(_p({'hr': 72, 'steps': -1}), isNull);
    });
    test('CB7  C4=V C5=F C6=F: steps=1240 → lectura completa', () {
      final l = _p({'hr': 72, 'steps': 1240})!;
      expect((l.heartRate, l.steps), (72, 1240));
    });
  });

  group('WB-05 parse: valores límite', () {
    final casos = <Object, bool>{
      29: false, 30: true, 31: true, // límite inferior
      229: true, 230: true, 231: false, // límite superior
      29.9: false, 30.4: true, 229.6: true, 230.4: false, // decimales cerca del límite
    };
    casos.forEach((hr, valido) {
      test('hr=$hr → ${valido ? 'aceptada' : 'rechazada'}', () {
        expect(_p({'hr': hr}) != null, valido);
      });
    });
    test('La comparación se hace ANTES de redondear: 229.6 → 230 aceptada; 230.4 rechazada', () {
      expect(_p({'hr': 229.6})!.heartRate, 230);
      expect(_p({'hr': 30.4})!.heartRate, 30);
    });
    test('steps: 0 aceptado, -0.5 rechazado, 12.7 → 13', () {
      expect(_p({'hr': 80, 'steps': 0})!.steps, 0);
      expect(_p({'hr': 80, 'steps': -0.5}), isNull);
      expect(_p({'hr': 80, 'steps': 12.7})!.steps, 13);
    });
  });

  group('WB-04 _alRecibir: excepciones del protocolo TCP real', () {
    test('Ignora JSON inválido, JSON no-objeto, líneas >512 y lecturas fuera de rango', () async {
      final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);
      final hello = Completer<String>();
      server.listen((s) {
        s.cast<List<int>>().transform(utf8.decoder).listen((d) {
          if (!hello.isCompleted) hello.complete(d);
        });
        s.write('esto no es json\n'); // FormatException → se ignora
        s.write('[1,2,3]\n'); // JSON válido pero no Map
        s.write('{"hr":${'9' * 600}}\n'); // > 512 caracteres
        s.write('{"hr":500}\n'); // fuera de rango
        s.write('{"hr":75,"steps":10}\n'); // única válida
      });

      final w = WearableClient();
      addTearDown(w.dispose);
      await w.conectar(deviceId: 'd1', host: '127.0.0.1', port: server.port);
      expect(w.estado, WearableEstado.conectado);
      expect(await hello.future, 'CEOSMOS HELLO 1\n');
      await _esperar(() => w.muestras.isNotEmpty);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(w.muestras, [75]);
      expect(w.ultima!.steps, 10);
    });

    test('Límite del búfer: 3601 lecturas → se conservan las 3600 más recientes', () async {
      final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);
      server.listen((s) {
        final b = StringBuffer('{"hr":40}\n'); // la más antigua (se descarta)
        for (var i = 0; i < 3600; i++) {
          b.write('{"hr":${60 + i % 50}}\n');
        }
        s.write(b.toString());
      });
      final w = WearableClient();
      addTearDown(w.dispose);
      await w.conectar(deviceId: 'd1', host: '127.0.0.1', port: server.port);
      await _esperar(() => w.muestras.length == 3600 && w.muestras.last == 109);
      expect(w.muestras.first, 60);
      expect(w.muestras, isNot(contains(40)));
    });

    test('Puerto cerrado → estado error con mensaje (SocketException controlada)', () async {
      final libre = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final port = libre.port;
      await libre.close();
      final w = WearableClient();
      addTearDown(w.dispose);
      await w.conectar(deviceId: 'd1', host: '127.0.0.1', port: port);
      expect(w.estado, WearableEstado.error);
      expect(w.error, contains('No se pudo conectar'));
    });

    test('El dispositivo cierra la conexión → error y socket liberado', () async {
      final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);
      server.listen((s) async {
        s.write('{"hr":70}\n');
        await s.flush();
        await s.close();
      });
      final w = WearableClient();
      addTearDown(w.dispose);
      await w.conectar(deviceId: 'd1', host: '127.0.0.1', port: server.port);
      await _esperar(() => w.estado == WearableEstado.error);
      expect(w.error, 'El dispositivo cerró la conexión.');
    });
  });

  group('WB-05 Validaciones de acceso: valores límite', () {
    String clave(int n) => 'Aa1#${'x' * (n - 4)}';
    test('Contraseña: 7 rechazada, 8 aceptada, 72 aceptada, 73 rechazada', () {
      expect(AuthRepository.validarContrasenaNueva(clave(7)), 'Mínimo 8 caracteres.');
      expect(AuthRepository.validarContrasenaNueva(clave(8)), isNull);
      expect(AuthRepository.validarContrasenaNueva(clave(72)), isNull);
      expect(AuthRepository.validarContrasenaNueva(clave(73)), 'Máximo 72 caracteres.');
      expect(AuthRepository.validarContrasenaNueva(null), 'Mínimo 8 caracteres.');
    });
    test('Contraseña: falta cada clase de carácter (una condición a la vez)', () {
      for (final c in ['aa1#aaaa', 'AA1#AAAA', 'Aab#aaaa', 'Aa1aaaaa']) {
        expect(AuthRepository.validarContrasenaNueva(c), 'Usa mayúscula, minúscula, número y símbolo.', reason: c);
      }
    });
    test('Correo: vacío, con espacios, sin dominio y válido', () {
      expect(AuthRepository.validarCorreo(null), 'Escribe tu correo.');
      expect(AuthRepository.validarCorreo('   '), 'Escribe tu correo.');
      // 1.4.0: cualquier espacio se rechaza (antes «a b@c.com» era formato inválido y los de los extremos se recortaban).
      expect(AuthRepository.validarCorreo('a b@c.com'), 'No uses espacios.');
      expect(AuthRepository.validarCorreo('ana@ceosmos'), 'Escribe un correo válido.');
      expect(AuthRepository.validarCorreo(' ana@ceosmos.test '), 'No uses espacios.');
      expect(AuthRepository.validarCorreo('ana@ceosmos.test'), isNull);
    });
    test('Usuario: 2 y 31 rechazados; 3 y 30 aceptados', () {
      expect(AuthRepository.validarUsuario('ab'), isNotNull);
      expect(AuthRepository.validarUsuario('abc'), isNull);
      expect(AuthRepository.validarUsuario('a' * 30), isNull);
      expect(AuthRepository.validarUsuario('a' * 31), isNotNull);
    });
  });
}

Future<void> _esperar(bool Function() ok) async {
  for (var i = 0; i < 100 && !ok(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  expect(ok(), isTrue, reason: 'la condición no se cumplió a tiempo');
}

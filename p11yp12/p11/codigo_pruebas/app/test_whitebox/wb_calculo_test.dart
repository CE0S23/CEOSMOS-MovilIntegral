// Práctica 11 · Fase 2 · Métodos de PROCESAMIENTO / CÁLCULO
// 1) WearableClient.resumenSesion (lib/core/wearable.dart:48): promedio, mínimo
//    y máximo de la frecuencia cardiaca que se guardan en FocusSession.metadata.
//      D1  m.isEmpty || deviceId == null  → return {}      (C1, C2)
//      D2  reduce(min): a < b              (C3)
//      D3  reduce(max): a > b              (C4)
//      D4  if (ultima?.steps != null)      (C5)  → incluye lastSteps
//    V(G) = 5 decisiones atómicas + 1 = 6.
// 2) traducirError (lib/data/api_client.dart:94): mayor complejidad del núcleo
//    (V(G) ≈ 27). Se recorre cada rama con una tabla de casos.
// 3) AppState.remaining / progress: límites del temporizador.
import 'package:ceosmos_movil_integral/core/wearable.dart';
import 'package:ceosmos_movil_integral/data/api_client.dart';
import 'package:ceosmos_movil_integral/data/catalog.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_ceosmos_api.dart';

class _WearableFijo extends WearableClient {
  _WearableFijo(this._muestras, {String? id = 'band-1', int? steps})
    : _id = id,
      _ultima = WearableLectura(heartRate: 70, steps: steps, at: DateTime(2026)),
      super.base();
  final List<int> _muestras;
  final String? _id;
  final WearableLectura _ultima;
  @override
  WearableEstado get estado => WearableEstado.conectado;
  @override
  String? get error => null;
  @override
  String? get deviceId => _id;
  @override
  WearableLectura? get ultima => _ultima;
  @override
  List<int> get muestras => _muestras;
  @override
  Future<void> conectar({required String deviceId, required String host, required int port}) async {}
  @override
  Future<void> desconectar() async {}
  @override
  void marcarInicio() {}
}

void main() {
  group('resumenSesion: caminos independientes', () {
    test('CB1 C1=V: sin muestras → {} (no se guarda resumen vacío)', () {
      expect(_WearableFijo([]).resumenSesion(), isEmpty);
    });
    test('CB2 C1=F C2=V: muestras sin dispositivo → {}', () {
      expect(_WearableFijo([70], id: null).resumenSesion(), isEmpty);
    });
    test('CB3 una muestra: promedio = mín = máx; sin pasos (C5=F)', () {
      final w = _WearableFijo([72]).resumenSesion()['wearable'] as Map;
      expect(w, {
        'deviceId': 'band-1', 'transport': 'TCP', 'samples': 1,
        'avgHeartRate': 72.0, 'minHeartRate': 72, 'maxHeartRate': 72,
      });
    });
    test('CB4 varias muestras: C3 y C4 toman V y F; con pasos (C5=V)', () {
      final w = _WearableFijo([80, 60, 100, 61], steps: 1500).resumenSesion()['wearable'] as Map;
      expect(w['samples'], 4);
      expect(w['avgHeartRate'], 75.3); // 301/4 = 75.25 → 1 decimal
      expect((w['minHeartRate'], w['maxHeartRate'], w['lastSteps']), (60, 100, 1500));
    });
    test('Redondeo del promedio a 1 decimal: 60,61,61 → 60.7', () {
      final w = _WearableFijo([60, 61, 61]).resumenSesion()['wearable'] as Map;
      expect(w['avgHeartRate'], 60.7);
    });
    test('Límite superior del búfer: 3600 muestras', () {
      final w = _WearableFijo(List.filled(3600, 90)).resumenSesion()['wearable'] as Map;
      expect((w['samples'], w['avgHeartRate']), (3600, 90.0));
    });
  });

  group('traducirError: una prueba por rama (decisiones)', () {
    Map<String, Object> b(Object m) => {'message': m};
    final casos = <(int, Object?, String)>[
      (401, b('Invalid credentials'), 'Correo o contraseña incorrectos.'),
      (401, b('Password mismatch'), 'Correo o contraseña incorrectos.'),
      (401, b('Email not verified'), 'Tu correo aún no está verificado. Escribe el código que te enviamos.'),
      (403, b('Account disabled'), 'Tu cuenta está desactivada. Contacta a un administrador.'),
      (401, b('Account locked'), 'Cuenta bloqueada temporalmente por intentos fallidos. Intenta más tarde.'),
      (429, b('ThrottlerException: Too Many Requests'), 'Demasiados intentos. Espera un momento e inténtalo de nuevo.'),
      (429, null, 'Demasiados intentos. Espera un momento e inténtalo de nuevo.'),
      (400, b('Email or username already in use'), 'Ese correo o nombre de usuario ya está registrado.'),
      (400, b('Invalid or expired code'), 'El código es incorrecto o ya venció.'),
      (400, b('Email already verified'), 'Ese correo ya estaba verificado.'),
      (404, b('User not found'), 'No encontramos una cuenta con ese correo.'),
      (401, b('Invalid or expired session'), 'Tu sesión expiró. Vuelve a iniciar sesión.'),
      (400, b('Invalid or expired reset token'), 'El enlace o código ya no es válido.'),
      (400, b(['Password must contain one uppercase']), 'La contraseña necesita mayúscula, minúscula, número y símbolo.'),
      (401, b('Unauthorized'), 'Tu sesión expiró. Vuelve a iniciar sesión.'),
      (403, b('Forbidden resource'), 'No tienes permiso para esta acción.'),
      (404, b('Cannot GET /api/x'), 'No se encontró el recurso solicitado.'),
      (409, b('Ese dispositivo ya está vinculado.'), 'Ese dispositivo ya está vinculado.'),
      (409, null, 'El registro ya existe.'),
      (409, b('This YouTube video is already saved'), 'Ese elemento ya está en tu biblioteca.'),
      (500, b('Internal server error'), 'El servidor de CEOSMOS tuvo un problema. Intenta más tarde.'),
      (503, '<html>Bad gateway</html>', 'El servidor de CEOSMOS tuvo un problema. Intenta más tarde.'),
      (400, b(['name must be shorter', 'address inválida']), 'name must be shorter address inválida'),
      (400, null, 'No se pudo completar la operación.'),
    ];
    for (final (status, body, esperado) in casos) {
      test('$status ${body is Map ? body['message'] : body}', () {
        expect(traducirError(status, body), esperado);
      });
    }
  });

  group('Temporizador: valores límite de remaining/progress', () {
    test('0 s, mitad, exacto y excedido', () async {
      var now = DateTime(2026, 11, 11, 12);
      final api = FakeCeosmosApi()..addUser('t@example.com', 'Clave#2026');
      final s = api.appState(now: () => now);
      addTearDown(s.dispose);
      await s.acceptSession(await s.auth.login('t@example.com', 'Clave#2026'));
      s.startSession(catalog.first, 5);
      expect((s.remaining, s.progress), (const Duration(minutes: 5), 0.0));
      now = now.add(const Duration(seconds: 150));
      expect((s.remaining.inSeconds, s.progress), (150, 0.5));
      now = now.add(const Duration(seconds: 150));
      expect((s.remaining, s.progress), (Duration.zero, 1.0));
      now = now.add(const Duration(minutes: 3)); // excedido: no sale del rango
      expect((s.remaining, s.progress), (Duration.zero, 1.0));
    });
    test('Excepciones: sesión sin usuario y duración fuera del catálogo', () async {
      final s = FakeCeosmosApi().appState();
      addTearDown(s.dispose);
      expect(() => s.startSession(catalog.first, 25), throwsStateError);
      await expectLater(s.setPreferredMinutes(7), throwsArgumentError);
    });
  });
}

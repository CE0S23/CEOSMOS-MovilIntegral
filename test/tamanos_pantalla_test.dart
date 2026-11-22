import 'dart:io';

import 'package:ceosmos_movil_integral/app.dart';
import 'package:ceosmos_movil_integral/core/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_ceosmos_api.dart';
import 'widget_test.dart' show mockAudio;

// Blindaje · barrido de tamaños de ventana (ventana flotante, pantalla dividida,
// teléfonos pequeños, tablets y escritorio). Por cada tamaño abre Acceso y las
// 6 pestañas y anota si algo se desborda. Escribe la tabla en
// evidencias/blindaje/ventana/barrido_tamanos.md cuando BARRIDO_EVIDENCIA=1.
//
// Regla de regresión: desde 240 × 320 dp no hay desbordes (200 dp de ancho queda fuera).
const _anchos = [200.0, 240.0, 280.0, 300.0, 320.0, 360.0, 412.0, 600.0, 768.0, 900.0, 1024.0, 1280.0, 1600.0];
const _altos = [320.0, 400.0, 480.0, 560.0, 640.0, 800.0, 1000.0];
const _iconos = [
  Icons.grid_view_rounded,
  Icons.explore_outlined,
  Icons.timelapse_rounded,
  Icons.devices_other_outlined,
  Icons.support_agent_outlined,
  Icons.person_outline_rounded,
];
const _nombres = ['Acceso', 'Inicio', 'Explorar', 'Mi sesión', 'Equipos', 'Soporte', 'Perfil'];

void main() {
  setUp(mockAudio);
  final resultados = <String, List<String>>{};

  for (final ancho in _anchos) {
    for (final alto in _altos) {
      testWidgets('Ventana ${ancho.toInt()} × ${alto.toInt()} dp', (tester) async {
        tester.view.physicalSize = Size(ancho, alto);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final fallas = <String>[];
        void anotar(String donde) {
          Object? e;
          while ((e = tester.takeException()) != null) {
            final txt = '$e'.split('\n').first;
            fallas.add('$donde: ${txt.length > 60 ? txt.substring(0, 60) : txt}');
          }
        }

        final api = FakeCeosmosApi()..addUser('ana@example.com', 'Clave#2026', username: 'Ana');
        final state = api.appState()..status = AuthStatus.signedOut;
        addTearDown(state.dispose);
        await tester.pumpWidget(CeosmosApp(state: state));
        await tester.pumpAndSettle();
        anotar(_nombres[0]);

        await state.acceptSession(await state.auth.login('ana@example.com', 'Clave#2026'));
        await tester.pumpAndSettle();
        for (var i = 0; i < _iconos.length; i++) {
          final f = find.byIcon(_iconos[i]);
          if (f.evaluate().isEmpty) {
            fallas.add('${_nombres[i + 1]}: pestaña no visible');
            continue;
          }
          await tester.tap(f.last, warnIfMissed: false);
          await tester.pumpAndSettle();
          anotar(_nombres[i + 1]);
        }
        await tester.pumpWidget(const SizedBox());
        resultados['${ancho.toInt()}x${alto.toInt()}'] = fallas;

        if (ancho >= 240) {
          expect(fallas, isEmpty, reason: fallas.join('\n'));
        }
      });
    }
  }

  tearDownAll(() {
    if (Platform.environment['BARRIDO_EVIDENCIA'] != '1') return;
    final b = StringBuffer()
      ..writeln('# Barrido de tamaños de ventana (prueba automática)')
      ..writeln()
      ..writeln('`flutter test test/tamanos_pantalla_test.dart` · densidad 1 · Acceso + 6 pestañas por tamaño.')
      ..writeln('✓ = sin desbordes · ✗n = n pantallas con desborde.')
      ..writeln()
      ..writeln('| alto \\ ancho | ${_anchos.map((a) => a.toInt()).join(' | ')} |')
      ..writeln('|---|${_anchos.map((_) => '---').join('|')}|');
    for (final alto in _altos) {
      final celdas = _anchos.map((a) {
        final f = resultados['${a.toInt()}x${alto.toInt()}'];
        if (f == null) return '?';
        final pantallas = f.map((x) => x.split(':').first).toSet().length;
        return f.isEmpty ? '✓' : '✗$pantallas';
      });
      b.writeln('| **${alto.toInt()}** | ${celdas.join(' | ')} |');
    }
    b..writeln()..writeln('## Detalle de desbordes');
    resultados.forEach((k, v) {
      if (v.isNotEmpty) b.writeln('- $k: ${v.toSet().join('; ')}');
    });
    File('evidencias/blindaje/ventana/barrido_tamanos.md').writeAsStringSync(b.toString());
  });
}

// 1.4.0 · Regresión de la alerta intermitente («pulso bajo» que no llegó en 70 s).
// Reproduce la prueba del equipo: Reloj en Reposo 20 s, se cambia de modo y se mide
// cuánto tarda la alerta esperada; 10 veces cada alerta (alta, muy alta y baja) en la
// MISMA sesión, como en el teléfono. Usa la réplica del simulador del Reloj.
import 'dart:math';

import 'package:ceosmos_movil_integral/core/alertas_salud.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/simulador_reloj.dart';

class Medicion {
  Medicion(this.alerta, this.segundos);
  final String alerta;
  final int? segundos; // null = no llegó en el plazo
}

/// Corre [repeticiones] ciclos alta → muy alta → baja con un motor y devuelve las mediciones.
List<Medicion> medir({
  required MotorAlertas motor,
  required Map<String, (ModoReloj, TipoAlerta)> casos,
  int repeticiones = 10,
  int semilla = 1,
  int plazo = 70,
}) {
  final sim = SimuladorReloj(Random(semilla));
  var t = DateTime(2026, 11, 26, 12);
  final out = <Medicion>[];
  void segundo() {
    motor.evaluar(sim.paso(), sim.modo.actividad, t);
    t = t.add(const Duration(seconds: 1));
  }

  for (var r = 0; r < repeticiones; r++) {
    for (final MapEntry(key: nombre, value: (modo, tipo)) in casos.entries) {
      sim.cambiarModo(ModoReloj.reposo);
      for (var s = 0; s < 20; s++) {
        segundo();
      }
      sim.cambiarModo(modo);
      int? llego;
      for (var s = 1; s <= plazo && llego == null; s++) {
        final a = motor.evaluar(sim.paso(), modo.actividad, t);
        t = t.add(const Duration(seconds: 1));
        if (a?.tipo == tipo) llego = s;
      }
      out.add(Medicion(nombre, llego));
    }
  }
  return out;
}

String resumen(List<Medicion> m) {
  final b = StringBuffer();
  for (final nombre in {for (final x in m) x.alerta}) {
    final de = m.where((x) => x.alerta == nombre).toList();
    final ok = [for (final x in de) if (x.segundos != null) x.segundos!]..sort();
    final med = ok.isEmpty ? '-' : (ok.length.isOdd ? '${ok[ok.length ~/ 2]}' : '${(ok[ok.length ~/ 2 - 1] + ok[ok.length ~/ 2]) / 2}');
    b.writeln('$nombre: ${ok.length}/${de.length} llegaron · fallidas ${de.length - ok.length} · '
        'mín ${ok.isEmpty ? '-' : ok.first} s · mediana $med s · máx ${ok.isEmpty ? '-' : ok.last} s');
  }
  return b.toString();
}

void main() {
  test('las 30 alertas llegan en menos de 30 s con los modos y el motor corregidos', () {
    for (final semilla in [1, 2, 3, 4, 5]) {
      final m = medir(
        motor: MotorAlertas(),
        semilla: semilla,
        casos: {
          'alta': (ModoReloj.alta, TipoAlerta.pulsoAlto),
          'muy alta': (ModoReloj.muyAlta, TipoAlerta.pulsoMuyAlto),
          'baja': (ModoReloj.baja, TipoAlerta.pulsoBajo),
        },
      );
      // ignore: avoid_print
      if (semilla == 1) print('DESPUÉS\n${resumen(m)}');
      expect(m.where((x) => x.segundos == null), isEmpty, reason: 'semilla $semilla\n${resumen(m)}');
      expect(m.every((x) => x.segundos! < 30), isTrue, reason: 'semilla $semilla\n${resumen(m)}');
    }
  });

  test('con los rangos anteriores del Reloj el motor también alerta siempre (ruido en el umbral)', () {
    for (final semilla in [1, 2, 3]) {
      final m = medir(
        motor: MotorAlertas(),
        semilla: semilla,
        casos: {
          'alta': (ModoReloj.altaAntes, TipoAlerta.pulsoAlto),
          'baja': (ModoReloj.bajaAntes, TipoAlerta.pulsoBajo),
        },
      );
      expect(m.where((x) => x.segundos == null), isEmpty, reason: 'semilla $semilla\n${resumen(m)}');
    }
  });
}

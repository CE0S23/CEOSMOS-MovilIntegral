// 1.4.0 · Regresión: «1 sesiones» y «1 experiencias». Todos los textos con contador
// usan `contar` (singular solo con 1).
import 'dart:io';

import 'package:ceosmos_movil_integral/core/plural.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('singular solo con 1 (y −1); 0 y el resto en plural', () {
    expect(contar(1, 'sesión', 'sesiones'), '1 sesión');
    expect(contar(0, 'sesión', 'sesiones'), '0 sesiones');
    expect(contar(2, 'sesión', 'sesiones'), '2 sesiones');
    expect(contar(-1, 'paso', 'pasos'), '-1 paso');
    expect(contar(1, 'experiencia guardada', 'experiencias guardadas'), '1 experiencia guardada');
    expect(contar(1.0, 'lectura', 'lecturas'), '1 lectura');
    expect(palabra(1, 'se omitió', 'se omitieron'), 'se omitió');
    expect(palabra(3, 'se omitió', 'se omitieron'), 'se omitieron');
  });

  test('ningún texto visible interpola un contador seguido de una palabra en plural sin `contar`', () {
    // Barrido del código: «${algo.length} sesiones» quedaría «1 sesiones».
    final sospechoso = RegExp(r"\$\{[^{}]*(length|count|total|Sessions|steps|samples|Minutes|edad|size)[^{}]*\}\s+(sesiones|experiencias|lecturas|pasos|minutos|años|registros|incidencias|documentos|alertas|equipos)\b");
    final hallados = <String>[];
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
      final lineas = f.readAsLinesSync();
      for (var i = 0; i < lineas.length; i++) {
        if (lineas[i].trimLeft().startsWith('//')) continue;
        if (sospechoso.hasMatch(lineas[i])) hallados.add('${f.path}:${i + 1}');
      }
    }
    expect(hallados, isEmpty);
  });
}

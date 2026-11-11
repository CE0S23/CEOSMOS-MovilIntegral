import 'package:flutter_test/flutter_test.dart';
import 'package:ceosmos_movil_integral/practicas/bd_flutter/reporte_validation.dart';

void main() {
  test('alta válida', () {
    expect(
      validarReporte(
        id: 'REP001',
        equipo: 'Bomba 1',
        descripcion: 'Fuga visible',
        prioridad: 'Media',
      ),
      isNull,
    );
  });

  test('campos obligatorios', () {
    expect(
      validarReporte(
        id: 'REP001',
        equipo: '',
        descripcion: '',
        prioridad: 'Media',
      ),
      'El equipo es obligatorio.',
    );
    expect(
      validarReporte(
        id: 'REP001',
        equipo: 'Bomba',
        descripcion: '',
        prioridad: 'Media',
      ),
      'La descripción es obligatoria.',
    );
  });

  test('id inválido', () {
    expect(validarId('REP9999'), 'El ID debe tener el formato REP001.');
  });
}

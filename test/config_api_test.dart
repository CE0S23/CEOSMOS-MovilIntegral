import 'package:ceosmos_movil_integral/core/config.dart';
import 'package:flutter_test/flutter_test.dart';

// Blindaje · regresión: un release compilado sin --dart-define apuntaba a 10.0.2.2.
void main() {
  test('release sin URL definida → producción', () {
    expect(AppConfig.resolverApi(definida: '', release: true, android: true), AppConfig.produccion);
    expect(AppConfig.produccion, startsWith('https://'));
  });

  test('la URL definida al compilar siempre manda', () {
    expect(
      AppConfig.resolverApi(definida: 'https://otra.example/api', release: true, android: true),
      'https://otra.example/api',
    );
  });

  test('depuración sin URL → API local (emulador o escritorio)', () {
    expect(AppConfig.resolverApi(definida: '', release: false, android: true), 'http://10.0.2.2:8081/api');
    expect(AppConfig.resolverApi(definida: '', release: false, android: false), 'http://localhost:8081/api');
  });
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// Blindaje · regresiones de los scripts de operación (22/11):
//  * El usuario torpe desinstaló la app REAL del S24 porque el sufijo .monkey no se
//    aplicó (ORG_GRADLE_PROJECT_ no llegó a Gradle). Deben seguir el marcador, la
//    comprobación con aapt2 y la alarma de reinstalación.
//  * Nunca `adb shell monkey` (bloqueó el S24 el 21/11).
//  * arreglo_rapido compila contra producción y verifica que la app llega a ella.
void main() {
  String leer(String ruta) => File(ruta).readAsStringSync();

  test('la build aislada se activa con el marcador, no solo con la variable', () {
    final gradle = leer('android/app/build.gradle.kts');
    expect(gradle, contains('file(".ceosmos_monkey").exists()'));
    expect(gradle, contains('applicationIdSuffix = ".monkey"'));
  });

  test('mono_bloques comprueba el paquete antes de correr y vigila la app real', () {
    final s = leer('scripts/mono_bloques.ps1');
    expect(s, contains('.ceosmos_monkey'));
    expect(s, contains('aapt2'));
    expect(s, contains(r'$paquete -ne "$real.monkey"'));
    expect(s, contains('firstInstallTime'));
  });

  test('ningún script de operación usa adb shell monkey', () {
    for (final f in ['scripts/arreglo_rapido.ps1', 'scripts/arreglo_rapido.sh', 'scripts/mono_bloques.ps1',
        'scripts/verificar_produccion.ps1', 'scripts/verificar_produccion.sh']) {
      expect(RegExp(r'shell\s+monkey').hasMatch(leer(f)), isFalse, reason: f);
    }
  });

  test('arreglo_rapido compila contra producción y verifica la conexión tras instalar', () {
    for (final f in ['scripts/arreglo_rapido.ps1', 'scripts/arreglo_rapido.sh']) {
      final s = leer(f);
      expect(s, contains('CEOSMOS_API_URL=https://ceosmos-api.vercel.app/api'), reason: f);
      expect(s, contains('verificar_produccion'), reason: f);
    }
    expect(leer('scripts/verificar_produccion.ps1'), contains('Correo o contrase'));
  });

  test('verificar_produccion espera el formulario en vez de una pausa fija (Tab S9, 22/11)', () {
    final ps = leer('scripts/verificar_produccion.ps1');
    expect(ps, isNot(contains('Start-Sleep -Seconds 6')));
    expect(ps, contains('foreach (\$i in 1..10)'));
    final sh = leer('scripts/verificar_produccion.sh');
    expect(sh, isNot(contains('MainActivity" >/dev/null; sleep 6')));
    expect(sh, contains('for i in 1 2 3 4 5 6 7 8 9 10'));
    // El mensaje se reconoce aunque la consola decodifique mal la «ñ».
    for (final s in [ps, sh]) {
      expect(s, contains('Correo o contrase.{1,8}a incorrectos'));
    }
    expect(sh, contains('MSYS_NO_PATHCONV=1'));
  });

  test('dev_backend: la API usa su propio puerto y MediConnect no hereda PORT (1.4.0)', () {
    final s = leer('scripts/dev_backend.ps1');
    expect(File('scripts/dev_backend.ps1').readAsBytesSync().take(3), [0xEF, 0xBB, 0xBF], reason: 'PowerShell 5.1 necesita el BOM para leer «°» y acentos');
    expect(s, contains(r'[int]$ApiPort = 8081'));
    expect(s, isNot(contains("\$env:PORT = '8080'")));
    final api = s.indexOf(r'$env:PORT = "$ApiPort"');
    final restaura = s.indexOf(r'Remove-Item Env:PORT');
    final medi = s.indexOf("-ArgumentList 'server.js'");
    expect(api, greaterThan(0));
    expect(restaura, greaterThan(api), reason: 'PORT se restaura después de arrancar la API');
    expect(medi, greaterThan(restaura), reason: '…y antes de arrancar MediConnect (conserva 3443)');
    expect(s.indexOf(r'Test-PuertoOcupado $ApiPort'), lessThan(api), reason: 'avisa si el puerto está ocupado');
    expect(s, contains('exit 2'));
    // La app y los scripts apuntan al mismo puerto en desarrollo.
    expect(leer('lib/core/config.dart'), contains('localhost:8081/api'));
    expect(leer('scripts/construir_pwa.ps1'), contains('localhost:8081/api'));
  });
}

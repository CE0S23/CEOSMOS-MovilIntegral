// Práctica 12 · Driver de integration_test/p12_perfil_app_test.dart: guarda los
// resultados en build/p12_perfil_app.json (o en P12_PERFIL_JSON).
import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver(
  responseDataCallback: (data) async {
    final f = File(Platform.environment['P12_PERFIL_JSON'] ?? 'build/p12_perfil_app.json');
    await f.create(recursive: true);
    await f.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
  },
);

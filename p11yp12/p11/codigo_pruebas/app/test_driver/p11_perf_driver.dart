// Práctica 11 · Driver de integration_test/p11_ui_perf_test.dart: guarda el
// resumen de rendimiento por cuadro en build/p11_ui_perf.json.
import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver(
  responseDataCallback: (data) async {
    final f = File('build/p11_ui_perf.json');
    await f.create(recursive: true);
    await f.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
  },
);

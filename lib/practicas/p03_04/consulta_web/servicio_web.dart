import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class ServicioWeb {
  Future<String> consultar() async {
    final cliente = http.Client();
    try {
      final respuesta = await cliente
          .get(Uri.parse(urlConsulta))
          .timeout(const Duration(seconds: 10));
      if (respuesta.statusCode != 200) {
        throw http.ClientException('Respuesta HTTP ${respuesta.statusCode}');
      }
      final cuerpo = respuesta.body;
      try {
        return const JsonEncoder.withIndent('  ').convert(jsonDecode(cuerpo));
      } on FormatException {
        return cuerpo;
      }
    } finally {
      cliente.close();
    }
  }
}

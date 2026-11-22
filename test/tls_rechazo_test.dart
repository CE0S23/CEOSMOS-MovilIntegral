import 'dart:io';

import 'package:ceosmos_movil_integral/data/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_test/flutter_test.dart';

// Blindaje · interceptación (mitmproxy, portal cautivo con HTTPS): un certificado
// no confiable se rechaza y el usuario ve un mensaje claro, no la excepción cruda.
void main() {
  test('certificado no confiable → ApiException con mensaje para el usuario', () async {
    final api = ApiClient(
      baseUrl: 'https://ceosmos-api.vercel.app/api',
      client: MockClient((_) async => throw const HandshakeException('CERTIFICATE_VERIFY_FAILED')),
    );
    await expectLater(
      api.get('/health'),
      throwsA(isA<ApiException>().having((e) => e.message, 'mensaje', contains('conexión segura'))),
    );
  });

  test('otro error de E/S de red → ApiException, no excepción cruda', () async {
    final api = ApiClient(
      baseUrl: 'https://ceosmos-api.vercel.app/api',
      client: MockClient((_) async => throw const OSError('red inaccesible')),
    );
    await expectLater(api.get('/health'), throwsA(isA<ApiException>()));
  });

  test('el cliente real rechaza un servidor con certificado autofirmado', () async {
    // Servidor HTTPS local con certificado autofirmado generado al vuelo (openssl).
    final dir = Directory.systemTemp.createTempSync('tls');
    addTearDown(() => dir.deleteSync(recursive: true));
    final r = await Process.run('openssl', [
      'req', '-x509', '-newkey', 'rsa:2048', '-nodes', '-days', '1', '-subj', '/CN=localhost',
      '-keyout', '${dir.path}/k.pem', '-out', '${dir.path}/c.pem',
    ]).catchError((_) => ProcessResult(0, 127, '', 'sin openssl'));
    if (r.exitCode != 0) {
      markTestSkipped('openssl no disponible');
      return;
    }
    final ctx = SecurityContext()
      ..useCertificateChain('${dir.path}/c.pem')
      ..usePrivateKey('${dir.path}/k.pem');
    final server = await HttpServer.bindSecure(InternetAddress.loopbackIPv4, 0, ctx);
    addTearDown(() => server.close(force: true));
    server.listen((req) => req.response
      ..write('{"ok":true}')
      ..close());
    final api = ApiClient(baseUrl: 'https://localhost:${server.port}', client: http.Client());
    await expectLater(api.get('/health'), throwsA(isA<ApiException>()));
  });
}

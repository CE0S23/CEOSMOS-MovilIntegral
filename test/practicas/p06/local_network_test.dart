import 'package:flutter_test/flutter_test.dart';
import 'package:ceosmos_movil_integral/practicas/p06/local_network.dart';

void main() {
  test('acepta IP Wi-Fi de la interfaz y no inventa IP sin red', () {
    final wifi = LocalNetworkInfo.fromMap({'ip': '10.13.43.205', 'prefixLength': 18});
    expect(wifi.ip, '10.13.43.205');
    expect(wifi.prefixLength, 18);
    final offline = LocalNetworkInfo.fromMap({'ip': null, 'message': 'Sin Wi-Fi'});
    expect(offline.ip, isNull);
    expect(offline.message, 'Sin Wi-Fi');
    expect(LocalNetworkInfo.fromMap({'ip': '127.0.0.1'}).ip, isNull);
  });

  test('rechaza direcciones inválidas, localhost, multicast y dirección propia', () {
    const wifi = LocalNetworkInfo(ip: '192.168.1.10', message: 'Wi-Fi');
    for (final value in ['', '127.0.0.1', '0.0.0.0', '224.0.0.1', '255.255.255.255',
      '192.168.1.256', '192.168.1', '192.168.01.2', 'localhost', '192.168.1.10']) {
      expect(wifi.validatePeer(value), isNotNull, reason: value);
    }
    expect(wifi.validatePeer('192.168.1.20'), isNull);
  });

  test('sin IP Wi-Fi no permite iniciar conexión a otro teléfono', () {
    const offline = LocalNetworkInfo(message: 'Conecta Wi-Fi');
    expect(offline.validatePeer('192.168.1.20'), 'Conecta Wi-Fi');
  });
}

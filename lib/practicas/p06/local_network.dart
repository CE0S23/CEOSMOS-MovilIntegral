class LocalNetworkInfo {
  const LocalNetworkInfo({this.ip, this.prefixLength, required this.message});

  final String? ip;
  final int? prefixLength;
  final String message;

  factory LocalNetworkInfo.fromMap(Map<Object?, Object?> data) {
    final value = data['ip'];
    final ip = value is String && isUsableIpv4(value) ? value : null;
    final prefix = data['prefixLength'];
    return LocalNetworkInfo(
      ip: ip,
      prefixLength: prefix is int && prefix >= 0 && prefix <= 32 ? prefix : null,
      message: ip != null ? 'Red Wi-Fi actual' :
          data['message'] as String? ?? 'Conéctate a una red Wi-Fi con dirección IPv4.',
    );
  }

  static bool isUsableIpv4(String value) {
    final parts = value.split('.');
    if (parts.length != 4) return false;
    final numbers = <int>[];
    for (final part in parts) {
      if (!RegExp(r'^(0|[1-9][0-9]{0,2})$').hasMatch(part)) return false;
      final number = int.parse(part);
      if (number > 255) return false;
      numbers.add(number);
    }
    return numbers.first > 0 && numbers.first < 224 && numbers.first != 127;
  }

  String? validatePeer(String value) {
    if (ip == null) return message;
    final peer = value.trim();
    if (peer.isEmpty) return 'Escribe la IP Wi-Fi que aparece en el dispositivo A.';
    if (!isUsableIpv4(peer)) return 'Escribe una dirección IPv4 de red válida.';
    if (peer == ip) return 'Escribe la IP del otro teléfono, no la de este dispositivo.';
    return null;
  }
}

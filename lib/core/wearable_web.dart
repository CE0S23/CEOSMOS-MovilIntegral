import 'wearable.dart';

/// En navegador no hay sockets TCP: el wearable se vincula desde el móvil.
class WearableClientImpl extends WearableClient {
  WearableClientImpl() : super.base();

  @override
  WearableEstado get estado => WearableEstado.error;
  @override
  String? get error => 'La conexión TCP con el wearable solo está disponible en la app móvil.';
  @override
  String? get deviceId => null;
  @override
  WearableLectura? get ultima => null;
  @override
  List<int> get muestras => const [];

  @override
  Future<void> conectar({required String deviceId, required String host, required int port}) async =>
      notifyListeners();
  @override
  Future<void> desconectar() async {}
  @override
  void marcarInicio() {}
}

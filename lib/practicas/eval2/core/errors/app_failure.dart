import 'package:dio/dio.dart';

/// Error controlado que las pantallas pueden mostrar sin detalles tecnicos.
class AppFailure implements Exception {
  final int? status;
  final String code;
  final String message;
  const AppFailure(this.code, this.message, {this.status});

  static const secureConnection =
      AppFailure('INSECURE_CONNECTION', 'No se pudo establecer una conexión segura.');

  factory AppFailure.fromDio(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] is Map) {
      final err = data['error'] as Map;
      return AppFailure('${err['code']}', '${err['message']}', status: e.response?.statusCode);
    }
    if (e.error is AppFailure) return e.error as AppFailure;
    if (e.type == DioExceptionType.badCertificate ||
        e.error.toString().contains('HandshakeException') ||
        e.error.toString().contains('CERTIFICATE')) {
      return secureConnection;
    }
    if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
      return const AppFailure('TIMEOUT', 'El servidor tardó demasiado en responder.');
    }
    return AppFailure('NETWORK', 'Sin conexión con el servidor. Intenta más tarde.', status: e.response?.statusCode);
  }

  @override
  String toString() => message;
}

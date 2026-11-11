import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import '../config/app_config.dart';
import '../errors/app_failure.dart';
import '../storage/secure_storage.dart';

/// Unico punto de salida a la red. Solo HTTPS, certificate pinning,
/// timeouts de 10 s y token en Authorization con renovacion automatica.
class ApiClient {
  final Dio dio;
  final SecureStorage storage;
  void Function()? onSessionExpired;

  ApiClient(this.storage, {String? baseUrl, String? pinnedPem})
      : dio = Dio(BaseOptions(
          baseUrl: baseUrl ?? AppConfig.apiBaseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          contentType: 'application/json',
        )) {
    // Certificate pinning: solo se confia en el certificado fijado,
    // no en las autoridades del sistema ni en las instaladas por el usuario (Burp, etc.).
    dio.httpClientAdapter = IOHttpClientAdapter(createHttpClient: () {
      final ctx = SecurityContext(withTrustedRoots: false)
        ..setTrustedCertificatesBytes(utf8.encode(pinnedPem ?? AppConfig.pinnedCertPem));
      return HttpClient(context: ctx)..badCertificateCallback = (_, _, _) => false; // [CEOSMOS] lint: comodines de Dart 3
    });
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (options.uri.scheme != 'https') {
          // HTTP en claro prohibido: la peticion nunca sale del telefono.
          return handler.reject(DioException(requestOptions: options, error: AppFailure.secureConnection));
        }
        final token = await storage.accessToken;
        if (token != null && options.headers['Authorization'] == null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (e, handler) async {
        final isRetry = e.requestOptions.extra['retried'] == true;
        if (e.response?.statusCode == 401 && !isRetry && !e.requestOptions.path.contains('/auth/')) {
          final refresh = await storage.refreshToken;
          if (refresh != null) {
            try {
              final r = await dio.post('/auth/refresh', data: {'refresh_token': refresh});
              await storage.saveTokens(r.data['access_token'], r.data['refresh_token']);
              final opts = e.requestOptions
                ..extra['retried'] = true
                ..headers['Authorization'] = 'Bearer ${r.data['access_token']}';
              return handler.resolve(await dio.fetch(opts));
            } catch (_) {}
          }
          await storage.clear();
          onSessionExpired?.call();
        }
        handler.next(e);
      },
    ));
  }
}

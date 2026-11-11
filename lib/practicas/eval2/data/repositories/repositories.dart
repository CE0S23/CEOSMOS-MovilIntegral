import 'package:dio/dio.dart';

import '../../core/errors/app_failure.dart';
import '../../core/network/api_client.dart';
import '../models/models.dart';

/// Las pantallas solo hablan con estos repositorios, nunca con Dio.
Future<T> _guard<T>(Future<T> Function() f) async {
  try {
    return await f();
  } on DioException catch (e) {
    throw AppFailure.fromDio(e);
  }
}

class AuthRepository {
  final ApiClient api;
  AuthRepository(this.api);

  /// Sin validacion local de contrasenas: siempre decide el servidor.
  Future<String> login(String email, String password) => _guard(() async {
        final r = await api.dio.post('/auth/login', data: {'email': email, 'password': password});
        final d = r.data;
        if (d is! Map || d['access_token'] is! String || d['refresh_token'] is! String) {
          throw const AppFailure('BAD_RESPONSE', 'Ocurrió un error, intenta más tarde.');
        }
        await api.storage.saveTokens(d['access_token'], d['refresh_token']);
        return '${d['user']?['name'] ?? ''}';
      });

  Future<void> logout() async {
    final refresh = await api.storage.refreshToken;
    try {
      await api.dio.post('/auth/logout', data: {'refresh_token': refresh});
    } catch (_) {}
    await api.storage.clear();
  }
}

class AppointmentRepository {
  final ApiClient api;
  AppointmentRepository(this.api);

  Future<AppointmentPage> myAppointments({String path = '/appointments/me?page=1&limit=20'}) =>
      _guard(() async => AppointmentPage.fromJson((await api.dio.get(path)).data));

  Future<List<Doctor>> doctors() => _guard(() async {
        final d = (await api.dio.get('/doctors')).data;
        if (d is! Map || d['data'] is! List) throw const AppFailure('BAD_RESPONSE', 'No pudimos cargar los doctores.');
        return [
          for (final x in d['data'])
            if (x is Map && x['id'] is String) Doctor(x['id'], '${x['name']}', '${x['specialty']}')
        ];
      });

  Future<Map> create(String doctorId, String date, String reason, String idempotencyKey) => _guard(() async {
        final r = await api.dio.post('/appointments',
            data: {'doctor_id': doctorId, 'date': date, 'reason': reason},
            options: Options(headers: {'Idempotency-Key': idempotencyKey}));
        if (r.data is! Map || r.data['appointment_id'] is! String) {
          throw const AppFailure('BAD_RESPONSE', 'Ocurrió un error, intenta más tarde.');
        }
        return r.data as Map;
      });
}

class HealthInfoRepository {
  final ApiClient api;
  HealthInfoRepository(this.api);
  Future<HealthInfo> fetch() => _guard(() async => HealthInfo.fromJson((await api.dio.get('/health-info')).data));
}

/// Acciones del laboratorio de pruebas (solo con --dart-define=LAB_MODE=true).
class LabRepository {
  final ApiClient api;
  LabRepository(this.api);

  Future<String> raw(String method, String path, {Object? data}) async {
    final sw = Stopwatch()..start();
    try {
      final r = await api.dio.request(path, data: data, options: Options(method: method));
      return 'HTTP ${r.statusCode} · ${sw.elapsedMilliseconds} ms\n${r.data}';
    } on DioException catch (e) {
      final f = AppFailure.fromDio(e);
      return '${f.status != null ? 'HTTP ${f.status}' : 'Sin respuesta'} · ${sw.elapsedMilliseconds} ms\n${f.code}: ${f.message}';
    }
  }
}

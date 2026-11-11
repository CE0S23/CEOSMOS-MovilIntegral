import 'package:flutter/foundation.dart';

import '../../core/errors/app_failure.dart';

/// Modelos con validacion estricta: si la respuesta no cumple, se rechaza.
class Appointment {
  final String id;
  final DateTime date;
  final String doctor;
  final String specialty;
  final String status;
  Appointment(this.id, this.date, this.doctor, this.specialty, this.status);

  /// Devuelve null si el registro esta incompleto (se omite y se registra).
  static Appointment? tryParse(dynamic j) {
    if (j is! Map) return null;
    final id = j['appointment_id'], date = j['date'];
    final parsed = date is String ? DateTime.tryParse(date) : null;
    if (id is! String || parsed == null) {
      debugPrint('[MediConnect] Cita descartada por formato inválido: ${j['appointment_id'] ?? '(sin id)'}');
      return null;
    }
    return Appointment(id, parsed.toLocal(), '${j['doctor'] ?? ''}', '${j['specialty'] ?? ''}', '${j['status'] ?? ''}');
  }
}

class AppointmentPage {
  final List<Appointment> items;
  final int omitted;
  AppointmentPage(this.items, this.omitted);

  static const loadError = AppFailure('BAD_RESPONSE', 'No pudimos cargar tus citas, intenta más tarde.');

  factory AppointmentPage.fromJson(dynamic j) {
    if (j is! Map || j['data'] is! List) throw loadError;
    final list = j['data'] as List;
    final items = list.map(Appointment.tryParse).whereType<Appointment>().toList();
    return AppointmentPage(items, list.length - items.length);
  }
}

class Doctor {
  final String id, name, specialty;
  Doctor(this.id, this.name, this.specialty);
}

class HealthInfo {
  final String? clinicStatus;
  final List<MapEntry<String, String>> tips;
  final bool degraded;
  final String? message;
  HealthInfo(this.clinicStatus, this.tips, this.degraded, this.message);

  factory HealthInfo.fromJson(dynamic j) {
    if (j is! Map) throw const AppFailure('BAD_RESPONSE', 'Información no disponible por el momento.');
    final d = j['data'];
    final tips = <MapEntry<String, String>>[];
    if (d is Map && d['tips'] is List) {
      for (final t in d['tips']) {
        if (t is Map && t['title'] is String && t['body'] is String) tips.add(MapEntry(t['title'], t['body']));
      }
    }
    return HealthInfo(d is Map ? d['clinic_status'] as String? : null, tips, j['degraded'] == true, j['message'] as String?);
  }
}

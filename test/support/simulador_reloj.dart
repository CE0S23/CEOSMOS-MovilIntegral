// Réplica en Dart del generador de pulso del Reloj (`companion/.../Simulador.kt`) para
// reproducir en pruebas lo que ve CEOSMOS: 1 lectura por segundo, el pulso avanza hacia
// un objetivo del rango del modo (≤ 4 bpm/s; 8 en los modos de alerta) con ruido de ±1 bpm y el objetivo cambia
// cada 8–12 s. Debe mantenerse igual que el Kotlin (mismos rangos y constantes).
import 'dart:math';

class ModoReloj {
  const ModoReloj(this.nombre, this.actividad, this.hrMin, this.hrMax, {this.alerta = false});
  final String nombre, actividad;
  final int hrMin, hrMax;
  final bool alerta;

  static const reposo = ModoReloj('Reposo', 'reposo', 60, 75);
  static const alta = ModoReloj('Frecuencia alta', 'reposo', 125, 175, alerta: true);
  static const muyAlta = ModoReloj('Frecuencia muy alta', 'reposo', 190, 210, alerta: true);
  static const baja = ModoReloj('Frecuencia baja', 'reposo', 36, 43, alerta: true);

  /// Rangos ANTERIORES a la corrección (1.4.0 inicial): «alta» 150–190 mezclaba pulso
  /// alto y muy alto, y «baja» 35–45 llegaba justo al umbral de 45; cambio a 4 bpm/s.
  static const altaAntes = ModoReloj('Frecuencia alta (antes)', 'reposo', 150, 190);
  static const bajaAntes = ModoReloj('Frecuencia baja (antes)', 'reposo', 35, 45);
}

class SimuladorReloj {
  SimuladorReloj(this._azar, {double hrInicial = 70}) : hr = hrInicial, _objetivo = hrInicial;
  final Random _azar;
  ModoReloj modo = ModoReloj.reposo;
  double hr;
  double _objetivo;
  double _segundosObjetivo = 0;

  static const maxCambioPorSeg = 4.0, maxCambioAlertaPorSeg = 8.0, ruido = 1.0;

  void cambiarModo(ModoReloj m) {
    if (m == modo) return;
    modo = m;
    _segundosObjetivo = 0;
  }

  /// Lectura entera del siguiente segundo.
  int paso() {
    _segundosObjetivo -= 1;
    if (_segundosObjetivo <= 0 || _objetivo < modo.hrMin || _objetivo > modo.hrMax) {
      _objetivo = modo.hrMin + _azar.nextDouble() * (modo.hrMax - modo.hrMin);
      _segundosObjetivo = 8 + _azar.nextDouble() * 4;
    }
    final max = modo.alerta ? maxCambioAlertaPorSeg : maxCambioPorSeg;
    final delta = (_objetivo - hr).clamp(-max, max);
    hr = (hr + delta + (_azar.nextDouble() * 2 - 1) * ruido).clamp(30, 230).toDouble();
    return hr.toInt().clamp(30, 230);
  }
}

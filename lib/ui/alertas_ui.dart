import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/alertas_salud.dart';
import '../core/app_state.dart';
import 'theme.dart';
import 'widgets.dart';

const _sistema = MethodChannel('ceosmos/sistema');

/// Ruta en Ajustes para activar las notificaciones si se negó el permiso.
const rutaAjustesNotificaciones = 'Ajustes › Aplicaciones › CEOSMOS › Notificaciones';

Future<void> _abrirAjustes() async {
  try {
    await _sistema.invokeMethod<void>('abrirAjustesApp');
  } on PlatformException {
    // Sin canal (pruebas o web).
  } on MissingPluginException {
    // Igual que arriba.
  }
}

/// Aviso dentro de la app cuando llega una alerta (ícono + texto, no solo color).
void mostrarAvisoAlerta(BuildContext context, AlertaSalud a) {
  final p = context.paleta;
  ScaffoldMessenger.maybeOf(context)
    ?..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        key: const ValueKey('aviso-alerta-salud'),
        duration: const Duration(seconds: 6),
        content: Row(
          children: [
            Icon(a.urgente ? Icons.warning_rounded : Icons.monitor_heart_outlined, color: p.advertencia),
            const SizedBox(width: 12),
            Expanded(child: Text('${a.texto} (pulso simulado)')),
          ],
        ),
      ),
    );
}

/// Interruptor «Alertas de salud» de Perfil › Cuenta y herramientas.
class InterruptorAlertas extends StatefulWidget {
  const InterruptorAlertas({super.key, required this.state});
  final AppState state;

  @override
  State<InterruptorAlertas> createState() => _InterruptorAlertasState();
}

class _InterruptorAlertasState extends State<InterruptorAlertas> {
  bool _sinPermiso = false;

  Future<void> _cambiar(bool valor) async {
    if (valor && !kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      // Explicación antes de que Android pida el permiso (Android 13+).
      final seguir = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          icon: const Icon(Icons.notifications_active_outlined),
          title: const Text('Alertas de salud'),
          content: const Text(
            'CEOSMOS te avisará si el pulso del Reloj se mantiene alto en reposo, muy alto o bajo. '
            'Para avisarte aunque la app esté cerrada, Android te pedirá permiso de notificaciones.\n\n'
            'El pulso del Reloj CEOSMOS es simulado: no es una medición médica.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Ahora no')),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Continuar')),
          ],
        ),
      );
      if (seguir != true) return;
    }
    final concedido = await widget.state.setAlertasActivadas(valor);
    if (!mounted) return;
    setState(() => _sinPermiso = valor && !concedido && !kIsWeb && defaultTargetPlatform == TargetPlatform.android);
  }

  @override
  Widget build(BuildContext context) {
    final activas = widget.state.alertasActivadas;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          key: const ValueKey('interruptor-alertas'),
          contentPadding: EdgeInsets.zero,
          secondary: Icon(
            activas ? Icons.monitor_heart_outlined : Icons.heart_broken_outlined,
            color: context.paleta.enlace,
          ),
          title: const Text('Alertas de salud'),
          subtitle: Text(
            activas
                ? 'Activadas: aviso en la app, notificación, Reloj y TV.'
                : 'Desactivadas: no se evalúa el pulso del Reloj.',
          ),
          value: activas,
          onChanged: _cambiar,
        ),
        if (_sinPermiso)
          Padding(
            padding: const EdgeInsets.only(bottom: Espacio.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Aviso(
                  'Sin permiso de notificaciones: verás las alertas dentro de la app, en el Reloj y en la TV. '
                  'Para recibirlas con la app cerrada, actívalas en $rutaAjustesNotificaciones.',
                  tipo: TipoAviso.advertencia,
                ),
                TextButton.icon(
                  onPressed: _abrirAjustes,
                  icon: const Icon(Icons.settings_outlined),
                  label: const Text('Abrir Ajustes'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

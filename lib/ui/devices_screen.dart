import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/wearable.dart';
import '../data/api_client.dart';
import '../domain/models.dart';
import 'ble_section.dart';
import 'theme.dart';
import 'widgets.dart';

final _direccion = RegExp(r'^[A-Za-z0-9.-]{1,63}:(\d{2,5})$');

class DevicesScreen extends StatelessWidget {
  const DevicesScreen({super.key, required this.state});
  final AppState state;

  Future<void> _vincular(BuildContext context) async {
    final valores = await showDialog<List<String>>(
      context: context,
      builder: (_) => FormDialog(
        title: 'Vincular wearable',
        confirmLabel: 'Vincular',
        fields: [
          DialogField(
            'Nombre',
            initial: 'CEOSMOS Band',
            maxLength: 40,
            validator: (v) => (v?.trim().isEmpty ?? true) ? 'Escribe un nombre.' : null,
          ),
          DialogField(
            'Dirección TCP (IP:puerto)',
            hint: '192.168.1.40:5050',
            keyboardType: TextInputType.url,
            validator: (v) {
              final m = _direccion.firstMatch(v?.trim() ?? '');
              final puerto = int.tryParse(m?.group(1) ?? '');
              if (m == null || puerto == null || puerto < 1 || puerto > 65535) {
                return 'Usa el formato IP:puerto.';
              }
              return null;
            },
          ),
        ],
      ),
    );
    if (valores == null || !context.mounted) return;
    final n = valores[0], d = valores[1];
    try {
      await state.linkWearable(n, d);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _desvincular(BuildContext context, LinkedDevice d) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('¿Desvincular ${d.name}?'),
        content: const Text('Se eliminará de tu cuenta. Tu historial se conserva.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Desvincular')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await state.unlinkDevice(d);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final devices = state.workspace.devices.where((d) => d.transport == 'TCP').toList();
    return ListenableBuilder(
      listenable: state.wearable,
      builder: (context, _) {
        final w = state.wearable;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageHeading(
              'Tu ecosistema',
              'Vincula tu wearable para ver tus métricas mientras te concentras.',
            ),
            BleSection(state: state),
            const SizedBox(height: 8),
            Text('Wearable por Wi-Fi (TCP/IP)', style: context.texto.headlineSmall),
            const SizedBox(height: 10),
            Panel(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.wifi_tethering, color: context.paleta.enlace),
                  SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Alternativa por red local: el wearable envía una línea JSON por lectura a IP:puerto. '
                      'Las vinculaciones (TCP y BLE) se guardan en tu cuenta.',
                      style: TextStyle(color: context.paleta.textoSecundario),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (devices.isEmpty)
              EmptyState(
                icon: Icons.watch_outlined,
                title: 'Sin dispositivos vinculados',
                message: 'Agrega la dirección IP y el puerto de tu CEOSMOS Band para conectarla.',
                action: FilledButton.icon(
                  onPressed: () => _vincular(context),
                  icon: const Icon(Icons.add_link),
                  label: const Text('Vincular wearable'),
                ),
              )
            else ...[
              for (final d in devices) ...[
                _Dispositivo(
                  device: d,
                  wearable: w,
                  onConectar: () => state.connectWearable(d),
                  onDesconectar: w.desconectar,
                  onDesvincular: () => _desvincular(context, d),
                ),
                const SizedBox(height: 14),
              ],
              OutlinedButton.icon(
                onPressed: () => _vincular(context),
                icon: const Icon(Icons.add_link),
                label: const Text('Vincular otro wearable'),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _Dispositivo extends StatelessWidget {
  const _Dispositivo({
    required this.device,
    required this.wearable,
    required this.onConectar,
    required this.onDesconectar,
    required this.onDesvincular,
  });
  final LinkedDevice device;
  final WearableClient wearable;
  final VoidCallback onConectar, onDesconectar, onDesvincular;

  @override
  Widget build(BuildContext context) {
    final propio = wearable.deviceId == device.id;
    final estado = propio ? wearable.estado : WearableEstado.desconectado;
    final lectura = propio ? wearable.ultima : null;
    final visto = device.lastSeenAt;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.watch_outlined, color: context.paleta.enlace, size: 30),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(device.name, style: context.texto.titleMedium),
                    Text('${device.transport} · ${device.address}', style: context.texto.bodySmall),
                    if (visto != null)
                      Text(
                        'Última conexión: ${visto.day}/${visto.month} ${visto.hour.toString().padLeft(2, '0')}:${visto.minute.toString().padLeft(2, '0')}',
                        style: context.texto.bodySmall,
                      ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Desvincular',
                onPressed: onDesvincular,
                icon: const Icon(Icons.link_off),
              ),
            ],
          ),
          const SizedBox(height: 14),
          switch (estado) {
            WearableEstado.conectando => const Row(
              children: [
                SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(width: 12),
                Text('Conectando…'),
              ],
            ),
            WearableEstado.conectado => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Tag('Conectado', color: context.paleta.exito, icon: Icons.check_circle),
                const SizedBox(height: 14),
                if (lectura == null)
                  Text('Esperando la primera lectura del dispositivo…', style: TextStyle(color: context.paleta.textoSecundario))
                else
                  Wrap(
                    spacing: 36,
                    runSpacing: 14,
                    children: [
                      _Metrica('${lectura.heartRate}', 'bpm', Icons.favorite_outline),
                      if (lectura.steps != null) _Metrica('${lectura.steps}', 'pasos', Icons.directions_walk),
                      _Metrica('${wearable.muestras.length}', 'lecturas', Icons.timeline),
                    ],
                  ),
                const SizedBox(height: 12),
                OutlinedButton(onPressed: onDesconectar, child: const Text('Desconectar')),
              ],
            ),
            WearableEstado.error => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Aviso(wearable.error ?? 'Error de conexión.'),
                const SizedBox(height: 10),
                FilledButton(onPressed: onConectar, child: const Text('Reintentar')),
              ],
            ),
            WearableEstado.desconectado => FilledButton.icon(
              onPressed: device.transport == 'TCP' ? onConectar : null,
              icon: const Icon(Icons.power_settings_new),
              label: const Text('Conectar'),
            ),
          },
        ],
      ),
    );
  }
}

class _Metrica extends StatelessWidget {
  const _Metrica(this.valor, this.etiqueta, this.icono);
  final String valor, etiqueta;
  final IconData icono;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icono, color: context.paleta.exito, size: 20),
      const SizedBox(height: 8),
      Text(valor, style: context.texto.headlineMedium),
      Text(etiqueta, style: context.texto.bodySmall),
    ],
  );
}

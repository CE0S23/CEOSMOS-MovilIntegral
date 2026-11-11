import 'package:flutter/material.dart';
import '../core/app_state.dart';
import 'theme.dart';
import 'widgets.dart';

class DevicesScreen extends StatelessWidget {
  const DevicesScreen({super.key, required this.state});
  final AppState state;
  @override
  Widget build(BuildContext context) {
    final band = state.workspace.devices.any((d) => d.type == 'wearable');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeading(
          'Tu ecosistema',
          'Una misma experiencia. Diferentes formas de acompañarte.',
        ),
        const Panel(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.science_outlined, color: Cosmos.peach),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Simulación de dispositivos',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Esta vista muestra cómo se integrará el ecosistema. No busca hardware ni establece conexiones reales. TCP/IP y BLE se incorporarán en el segundo parcial.',
                      style: TextStyle(color: Cosmos.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Panel(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Cosmos.lavender.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.smartphone_rounded,
                  color: Cosmos.lavender,
                  size: 34,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CEOSMOS Móvil',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 17,
                      ),
                    ),
                    Text(
                      'El centro de tu experiencia',
                      style: TextStyle(color: Cosmos.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.check_circle, color: Cosmos.mint),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(12),
          child: Center(child: Icon(Icons.more_vert, color: Cosmos.muted)),
        ),
        ...['wearable', 'tv'].map((type) {
          final linked = state.workspace.devices.any((d) => d.type == type);
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        type == 'wearable'
                            ? Icons.watch_outlined
                            : Icons.tv_rounded,
                        color: Cosmos.lavender,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          type == 'wearable' ? 'CEOSMOS Band' : 'CEOSMOS TV',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      Tag(
                        linked ? 'Demo activa' : 'Sin vincular',
                        color: linked ? Cosmos.mint : Cosmos.muted,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    type == 'wearable'
                        ? 'Tu ritmo y tu actividad, junto a tu sesión de enfoque.'
                        : 'Tu paisaje y tu sesión en una pantalla más grande.',
                    style: const TextStyle(color: Cosmos.muted),
                  ),
                  const SizedBox(height: 18),
                  OutlinedButton.icon(
                    onPressed: () => state.toggleDevice(type),
                    icon: Icon(linked ? Icons.link_off : Icons.add_link),
                    label: Text(
                      linked ? 'Desvincular demo' : 'Simular vinculación',
                    ),
                  ),
                  if (linked && type == 'tv')
                    Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: CosmosScene(
                        scene: state.currentMedia?.scene ?? 0,
                        height: 130,
                        child: Center(
                          child: Text(
                            state.currentMedia == null
                                ? 'TV simulada · Esperando sesión'
                                : '${state.currentMedia!.title}\n${clockLabel(state.remaining)}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
        if (band) ...[
          const SizedBox(height: 8),
          Text(
            'Vista previa de bienestar',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          const Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Tag('DATOS FICTICIOS', color: Cosmos.peach),
                SizedBox(height: 18),
                Wrap(
                  spacing: 36,
                  runSpacing: 18,
                  children: [
                    _Metric('72', 'bpm de muestra', Icons.favorite_outline),
                    _Metric('1,240', 'pasos de muestra', Icons.directions_walk),
                  ],
                ),
                SizedBox(height: 16),
                Text(
                  'Valores fijos para la presentación. No provienen de sensores ni representan una evaluación de salud.',
                  style: TextStyle(color: Cosmos.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.value, this.label, this.icon);
  final String value, label;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: Cosmos.mint, size: 20),
      const SizedBox(height: 10),
      Text(value, style: Theme.of(context).textTheme.headlineMedium),
      Text(label, style: const TextStyle(color: Cosmos.muted, fontSize: 12)),
    ],
  );
}

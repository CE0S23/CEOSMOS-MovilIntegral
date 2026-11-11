import 'package:flutter/material.dart';

import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'practica_host.dart';
import 'registro_practicas.dart';

/// Ventana «Prácticas»: lista de las prácticas de laboratorio integradas.
class PracticasScreen extends StatelessWidget {
  const PracticasScreen({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const PageHeading(
        'Prácticas',
        'Las prácticas del curso funcionando dentro de CEOSMOS. Cada una usa '
            'su propia base de datos o servicio, separado del de CEOSMOS.',
      ),
      for (final p in practicas) ...[
        _TarjetaPractica(practica: p),
        const SizedBox(height: 14),
      ],
    ],
  );
}

class _TarjetaPractica extends StatelessWidget {
  const _TarjetaPractica({required this.practica});
  final Practica practica;

  @override
  Widget build(BuildContext context) {
    final p = practica;
    return Semantics(
      button: true,
      label: 'Abrir ${p.numero} ${p.titulo}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('practica-${p.id}'),
          borderRadius: BorderRadius.circular(22),
          onTap: () => abrirPractica(context, p),
          child: Panel(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 64,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Cosmos.lavender.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    p.numero,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Cosmos.lavender,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.titulo,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        p.descripcion,
                        style: const TextStyle(color: Cosmos.muted),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          Tag(p.stack, icon: Icons.code),
                          Tag(p.datos, color: Cosmos.mint, icon: Icons.storage),
                          if (p.tipo == TipoPractica.nativa)
                            const Tag(
                              'Android nativo',
                              color: Cosmos.peach,
                              icon: Icons.android,
                            ),
                        ],
                      ),
                      if (p.requisito != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          p.requisito!,
                          style: const TextStyle(
                            color: Cosmos.peach,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Cosmos.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

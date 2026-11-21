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
        const SizedBox(height: Espacio.m + 2),
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
          borderRadius: Radios.bordeL,
          onTap: () => abrirPractica(context, p),
          child: Panel(
            padding: const EdgeInsets.all(Espacio.l + 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Número de práctica: bloque guinda con cifra en Bricolage.
                Container(
                  width: 64,
                  padding: const EdgeInsets.symmetric(vertical: Espacio.m),
                  decoration: BoxDecoration(
                    color: CeosmosColores.guinda,
                    borderRadius: Radios.bordeM,
                  ),
                  child: Text(
                    p.numero,
                    textAlign: TextAlign.center,
                    style: context.texto.titleSmall?.copyWith(
                      fontFamily: Fuentes.titulos,
                      color: CeosmosColores.blanco,
                    ),
                  ),
                ),
                const SizedBox(width: Espacio.m + 2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.titulo,
                        style: context.texto.titleLarge,
                      ),
                      const SizedBox(height: Espacio.xs),
                      Text(
                        p.descripcion,
                        style: TextStyle(color: context.paleta.textoSecundario),
                      ),
                      const SizedBox(height: Espacio.s + 2),
                      Wrap(
                        spacing: Espacio.s,
                        runSpacing: Espacio.s - 2,
                        children: [
                          Tag(p.stack, icon: Icons.code),
                          Tag(p.datos, color: context.paleta.exito, icon: Icons.storage),
                          if (p.tipo == TipoPractica.nativa)
                            Tag(
                              'Android nativo',
                              color: context.paleta.marca,
                              icon: Icons.android,
                            ),
                        ],
                      ),
                      if (p.requisito != null) ...[
                        const SizedBox(height: Espacio.s),
                        Aviso(
                          p.requisito!,
                          tipo: TipoAviso.advertencia,
                          style: context.texto.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: context.paleta.textoSecundario),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../core/referencias_academicas.dart';
import '../core/theme/theme.dart';
import '../practicas/practica_host.dart';
import '../practicas/registro_practicas.dart';
import 'widgets.dart';

/// Botón ⓘ «Referencia académica» del encabezado de cada función.
/// Desaparece por completo si [mostrarReferenciasAcademicas] es false.
class BotonReferenciaAcademica extends StatelessWidget {
  const BotonReferenciaAcademica({super.key, required this.id, this.color});
  final String id;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ref = referenciasAcademicas[id];
    if (!mostrarReferenciasAcademicas || ref == null) {
      return const SizedBox.shrink();
    }
    return IconButton(
      key: ValueKey('referencia-$id'),
      tooltip: 'Referencia académica',
      visualDensity: VisualDensity.compact,
      color: color ?? context.paleta.textoSecundario,
      icon: const Icon(Icons.info_outline, size: 20),
      onPressed: () => mostrarReferenciaAcademica(context, ref),
    );
  }
}

Future<void> mostrarReferenciaAcademica(
  BuildContext context,
  ReferenciaAcademica ref,
) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  builder: (context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(
        Espacio.xl,
        0,
        Espacio.xl,
        Espacio.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Referencia académica',
            style: context.texto.labelSmall?.copyWith(
              color: context.paleta.enlace,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: Espacio.s),
          Text(
            ref.practica,
            style: context.texto.titleLarge?.copyWith(
              color: context.paleta.marca,
            ),
          ),
          const SizedBox(height: Espacio.l),
          Text('Cómo se integró en CEOSMOS', style: context.texto.titleSmall),
          const SizedBox(height: Espacio.xs),
          Text(
            ref.integracion,
            style: TextStyle(color: context.paleta.textoSecundario),
          ),
        ],
      ),
    ),
  ),
);

/// Tarjeta que abre una función de CEOSMOS.
class TarjetaFuncion extends StatelessWidget {
  const TarjetaFuncion({super.key, required this.funcion});
  final Practica funcion;

  @override
  Widget build(BuildContext context) {
    final f = funcion;
    return Semantics(
      button: true,
      label: 'Abrir ${f.titulo}',
      child: Material(
        color: context.paleta.superficie,
        shape: RoundedRectangleBorder(
          borderRadius: Radios.bordeL,
          side: BorderSide(color: context.paleta.borde),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('funcion-${f.id}'),
          onTap: () => abrirPractica(context, f),
          child: Padding(
            padding: const EdgeInsets.all(Espacio.l),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: context.paleta.cianSuave,
                    borderRadius: Radios.bordeM,
                  ),
                  child: Icon(f.icono, color: context.paleta.enlace),
                ),
                const SizedBox(width: Espacio.m + 2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(f.titulo, style: context.texto.titleMedium),
                      const SizedBox(height: Espacio.xs),
                      Text(f.descripcion, style: context.texto.bodySmall),
                      if (f.requisito != null) ...[
                        const SizedBox(height: Espacio.s),
                        Aviso(
                          f.requisito!,
                          tipo: TipoAviso.info,
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

/// Lista de funciones de una sección con su título.
class GrupoFunciones extends StatelessWidget {
  const GrupoFunciones({
    super.key,
    required this.titulo,
    required this.seccion,
    this.descripcion,
  });
  final String titulo;
  final String? descripcion;
  final Seccion seccion;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(titulo, style: context.texto.headlineSmall),
      if (descripcion != null) ...[
        const SizedBox(height: Espacio.xs),
        Text(descripcion!, style: context.texto.bodySmall),
      ],
      const SizedBox(height: Espacio.m),
      for (final f in funcionesDe(seccion)) ...[
        TarjetaFuncion(funcion: f),
        const SizedBox(height: Espacio.m),
      ],
    ],
  );
}

/// Pestaña «Soporte»: tickets por rol, incidencias locales y reportes compartidos.
/// El aviso de conexión y la sincronización viven dentro de cada función.
class SoporteScreen extends StatelessWidget {
  const SoporteScreen({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const PageHeading(
        'Soporte',
        'Pide ayuda, da seguimiento a tus tickets y comparte reportes con tu equipo.',
      ),
      for (final f in funcionesDe(Seccion.soporte)) ...[
        TarjetaFuncion(funcion: f),
        const SizedBox(height: Espacio.m),
      ],
      const SizedBox(height: Espacio.l),
      const GrupoFunciones(
        titulo: 'Reportes e incidencias',
        descripcion:
            'Compartidos en tiempo real entre los equipos; cada uno conserva su propia base de datos.',
        seccion: Seccion.reportes,
      ),
    ],
  );
}

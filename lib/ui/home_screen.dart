import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../data/catalog.dart';
import '../domain/models.dart';
import 'tarjeta_equipos.dart';
import 'theme.dart';
import 'widgets.dart';
import '../core/plural.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.state,
    required this.onExplore,
    required this.onOpen,
    this.onEquipos,
  });
  final AppState state;
  final void Function(FocusMode?) onExplore;
  final ValueChanged<MediaItem> onOpen;

  /// Abre la pestaña Equipos (tarjeta «Tu Reloj y TV»).
  final VoidCallback? onEquipos;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _reflection = 0;
  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    // P12-O1: total calculado en el servidor (antes se sumaba solo el historial descargado).
    final minutes = state.totalMinutes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'UN MOMENTO PARA TI',
                    style: context.texto.labelSmall?.copyWith(
                      color: context.paleta.textoSecundario,
                      letterSpacing: 1.6,
                    ),
                  ),
                  const SizedBox(height: Espacio.s),
                  Text(
                    'Hola, ${state.user!.username.split(' ').first} ✦',
                    style: context.texto.headlineLarge?.copyWith(
                      color: context.paleta.marca,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Tag(
              state.dataError == null ? 'Sincronizado' : 'Sin conexión',
              color: state.dataError == null ? context.paleta.exito : context.paleta.advertencia,
              icon: state.dataError == null ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
            ),
          ],
        ),
        const SizedBox(height: Espacio.xl),
        CosmosScene(
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 310),
            padding: const EdgeInsets.all(Espacio.xl + 2),
            decoration: BoxDecoration(
              // Velo de tinta para que el texto blanco siempre cumpla AA.
              gradient: LinearGradient(
                colors: [
                  CeosmosColores.tinta.withValues(alpha: .72),
                  CeosmosColores.tinta.withValues(alpha: 0),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Tag(
                  'ENCUENTRA TU FLOW',
                  color: CeosmosColores.cian,
                  icon: Icons.auto_awesome,
                ),
                const SizedBox(height: Espacio.l + 2),
                Text(
                  'Un pequeño respiro.\nUn gran comienzo.',
                  style: context.texto.headlineLarge?.copyWith(
                    color: CeosmosColores.blanco,
                  ),
                ),
                const SizedBox(height: Espacio.m),
                Text(
                  'Crea espacio para lo que importa.',
                  style: context.texto.bodyLarge?.copyWith(
                    color: CeosmosColores.guindaClaro,
                  ),
                ),
                const SizedBox(height: Espacio.xl),
                FilledButton.icon(
                  // Sobre la escena oscura, el botón va en cian con texto guinda.
                  style: FilledButton.styleFrom(
                    backgroundColor: CeosmosColores.cian,
                    foregroundColor: CeosmosColores.guinda,
                  ),
                  onPressed: () => widget.onOpen(catalog.first),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(
                    state.hasSession
                        ? 'Elegir nueva sesión'
                        : 'Comenzar mi sesión',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: Espacio.xl),
        TarjetaEquipos(state: state, onEquipos: widget.onEquipos ?? () {}),
        const SizedBox(height: Espacio.xxl),
        Text(
          '¿Qué necesitas hoy?',
          style: context.texto.headlineSmall,
        ),
        const SizedBox(height: Espacio.xs + 2),
        Text(
          'Elige tu intención. Nosotros ponemos el ambiente.',
          style: TextStyle(color: context.paleta.textoSecundario),
        ),
        const SizedBox(height: Espacio.l + 2),
        LayoutBuilder(
          builder: (context, constraints) => Wrap(
            spacing: Espacio.m,
            runSpacing: Espacio.m,
            children: FocusMode.values
                .map(
                  (mode) => SizedBox(
                    width: constraints.maxWidth < 460
                        ? constraints.maxWidth
                        : (constraints.maxWidth - 24) / 3,
                    child: Material(
                      color: modeColor(context, mode).withValues(alpha: .08),
                      shape: RoundedRectangleBorder(
                        borderRadius: Radios.bordeL,
                        side: BorderSide(
                          color: modeColor(context, mode).withValues(alpha: .28),
                        ),
                      ),
                      child: InkWell(
                        borderRadius: Radios.bordeL,
                        onTap: () => widget.onExplore(mode),
                        child: Padding(
                          padding: const EdgeInsets.all(Espacio.l + 4),
                          child: Row(
                            children: [
                              Icon(
                                modeIcon(mode),
                                color: modeColor(context, mode),
                                size: 28,
                              ),
                              const SizedBox(width: Espacio.m),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      mode.label,
                                      style: context.texto.titleMedium,
                                    ),
                                    Text(
                                      switch (mode) {
                                        FocusMode.focus => 'Una cosa a la vez',
                                        FocusMode.relax => 'Baja el ritmo',
                                        FocusMode.inspire =>
                                          'Enciende una idea',
                                      },
                                      style: context.texto.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: Espacio.xxl),
        Row(
          children: [
            Expanded(
              child: Text(
                'Tu próxima pausa',
                style: context.texto.headlineSmall,
              ),
            ),
            TextButton(
              onPressed: () => widget.onExplore(null),
              child: const Text('Ver todo →'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth > 700
                ? 3
                : constraints.maxWidth > 480
                ? 2
                : 1;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: catalog
                  .take(3)
                  .map(
                    (item) => SizedBox(
                      width:
                          (constraints.maxWidth - 16 * (columns - 1)) / columns,
                      child: MediaCard(
                        item: item,
                        favorite: state.workspace.favorites.contains(item.id),
                        onOpen: () => widget.onOpen(item),
                        onFavorite: () => state.toggleFavorite(item.id),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
        const SizedBox(height: 28),
        Panel(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.format_quote, color: context.paleta.marca, size: 30),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reflections[_reflection],
                      style: context.texto.titleLarge?.copyWith(height: 1.35),
                    ),
                    const SizedBox(height: Espacio.s),
                    Text(
                      'UNA IDEA DE CEOSMOS',
                      style: context.texto.labelSmall?.copyWith(
                        letterSpacing: 1.6,
                        color: context.paleta.textoSecundario,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => setState(
                  () => _reflection = (_reflection + 1) % reflections.length,
                ),
                tooltip: 'Otra reflexión',
                icon: const Icon(Icons.refresh, size: 20),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 24,
          runSpacing: 10,
          children: [
            Text(
              '$minutes min de enfoque',
              style: TextStyle(color: context.paleta.textoSecundario),
            ),
            Text(
              contar(state.totalSessions, 'sesión guardada', 'sesiones guardadas'),
              style: TextStyle(color: context.paleta.textoSecundario),
            ),
            Text(
              'Tu progreso comienza aquí.',
              style: TextStyle(color: context.paleta.textoSecundario),
            ),
          ],
        ),
      ],
    );
  }
}

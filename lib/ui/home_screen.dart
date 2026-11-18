import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../data/catalog.dart';
import '../domain/models.dart';
import 'theme.dart';
import 'widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.state,
    required this.onExplore,
    required this.onOpen,
  });
  final AppState state;
  final void Function(FocusMode?) onExplore;
  final ValueChanged<MediaItem> onOpen;
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
                  const Text(
                    'UN MOMENTO PARA TI',
                    style: TextStyle(
                      color: Cosmos.muted,
                      fontSize: 11,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    'Hola, ${state.user!.username.split(' ').first} ✦',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Tag(
              state.dataError == null ? 'Sincronizado' : 'Sin conexión',
              color: state.dataError == null ? Cosmos.mint : Cosmos.peach,
              icon: state.dataError == null ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
            ),
          ],
        ),
        const SizedBox(height: 26),
        CosmosScene(
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 310),
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Cosmos.background.withValues(alpha: .7),
                  Colors.transparent,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Tag(
                  'ENCUENTRA TU FLOW',
                  color: Colors.white,
                  icon: Icons.auto_awesome,
                ),
                const SizedBox(height: 18),
                Text(
                  'Un pequeño respiro.\nUn gran comienzo.',
                  style: Theme.of(
                    context,
                  ).textTheme.headlineMedium?.copyWith(height: 1.15),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Crea espacio para lo que importa.',
                  style: TextStyle(color: Color(0xFFD4CFE2)),
                ),
                const SizedBox(height: 22),
                FilledButton.icon(
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
        const SizedBox(height: 30),
        Text(
          '¿Qué necesitas hoy?',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 6),
        const Text(
          'Elige tu intención. Nosotros ponemos el ambiente.',
          style: TextStyle(color: Cosmos.muted),
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) => Wrap(
            spacing: 12,
            runSpacing: 12,
            children: FocusMode.values
                .map(
                  (mode) => SizedBox(
                    width: constraints.maxWidth < 460
                        ? constraints.maxWidth
                        : (constraints.maxWidth - 24) / 3,
                    child: Material(
                      color: modeColor(mode).withValues(alpha: .07),
                      borderRadius: BorderRadius.circular(18),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => widget.onExplore(mode),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Icon(
                                modeIcon(mode),
                                color: modeColor(mode),
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      mode.label,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      switch (mode) {
                                        FocusMode.focus => 'Una cosa a la vez',
                                        FocusMode.relax => 'Baja el ritmo',
                                        FocusMode.inspire =>
                                          'Enciende una idea',
                                      },
                                      style: const TextStyle(
                                        color: Cosmos.muted,
                                        fontSize: 12,
                                      ),
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
        const SizedBox(height: 30),
        Row(
          children: [
            Expanded(
              child: Text(
                'Tu próxima pausa',
                style: Theme.of(context).textTheme.titleLarge,
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
              const Icon(Icons.format_quote, color: Cosmos.lavender, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reflections[_reflection],
                      style: const TextStyle(fontSize: 17, height: 1.5),
                    ),
                    const SizedBox(height: 9),
                    const Text(
                      'UNA IDEA DE CEOSMOS',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.8,
                        color: Cosmos.muted,
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
              style: const TextStyle(color: Cosmos.muted),
            ),
            Text(
              '${state.totalSessions} sesiones guardadas',
              style: const TextStyle(color: Cosmos.muted),
            ),
            const Text(
              'Tu progreso comienza aquí.',
              style: TextStyle(color: Cosmos.muted),
            ),
          ],
        ),
      ],
    );
  }
}

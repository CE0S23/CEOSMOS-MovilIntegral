import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../data/catalog.dart';
import '../domain/models.dart';
import 'theme.dart';
import 'library_section.dart';
import 'widgets.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({
    super.key,
    required this.state,
    required this.onOpen,
    this.initialMode,
    this.onlyFavorites = false,
  });
  final AppState state;
  final ValueChanged<MediaItem> onOpen;
  final FocusMode? initialMode;
  final bool onlyFavorites;
  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _search = TextEditingController();
  FocusMode? _mode;
  MediaKind? _kind;
  late bool _favorites;
  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    _favorites = widget.onlyFavorites;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = filterCatalog(
      query: _search.text,
      mode: _mode,
      kind: _kind,
      favorites: _favorites ? widget.state.workspace.favorites : null,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeading(
          'Explora tu cosmos',
          'Sonidos y paisajes para acompañar tu estado de ánimo.',
        ),
        TextField(
          controller: _search,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Buscar un sonido, un paisaje, una intención…',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _search.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Limpiar búsqueda',
                    onPressed: () => setState(_search.clear),
                    icon: const Icon(Icons.close),
                  ),
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Todos los modos'),
              selected: _mode == null,
              onSelected: (_) => setState(() => _mode = null),
            ),
            ...FocusMode.values.map(
              (mode) => ChoiceChip(
                label: Text(mode.label),
                selected: _mode == mode,
                onSelected: (_) => setState(() => _mode = mode),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChip(
              label: const Text('Audio'),
              avatar: const Icon(Icons.headphones, size: 16),
              selected: _kind == MediaKind.audio,
              onSelected: (v) =>
                  setState(() => _kind = v ? MediaKind.audio : null),
            ),
            FilterChip(
              label: const Text('Paisajes'),
              avatar: const Icon(Icons.landscape_outlined, size: 16),
              selected: _kind == MediaKind.image,
              onSelected: (v) =>
                  setState(() => _kind = v ? MediaKind.image : null),
            ),
            FilterChip(
              label: const Text('Mis favoritos'),
              avatar: const Icon(Icons.favorite_border, size: 16),
              selected: _favorites,
              onSelected: (v) => setState(() => _favorites = v),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          '${items.length} experiencias · Disponibles sin conexión',
          style: const TextStyle(color: Cosmos.muted, fontSize: 12),
        ),
        const SizedBox(height: 16),
        if (items.isEmpty)
          EmptyState(
            icon: _favorites ? Icons.favorite_border : Icons.search_off,
            title: _favorites
                ? 'Tu colección está por comenzar'
                : 'No encontramos esa experiencia',
            message: _favorites
                ? 'Guarda una experiencia con el corazón para encontrarla aquí.'
                : 'Prueba otra palabra o cambia los filtros.',
            action: OutlinedButton(
              onPressed: () => setState(() {
                _search.clear();
                _mode = null;
                _kind = null;
                _favorites = false;
              }),
              child: const Text('Mostrar todo'),
            ),
          ),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth > 760
                ? 3
                : constraints.maxWidth > 460
                ? 2
                : 1;
            return Wrap(
              spacing: 16,
              runSpacing: 18,
              children: items
                  .map(
                    (item) => SizedBox(
                      width:
                          (constraints.maxWidth - 16 * (columns - 1)) / columns,
                      child: MediaCard(
                        item: item,
                        favorite: widget.state.workspace.favorites.contains(
                          item.id,
                        ),
                        onOpen: () => widget.onOpen(item),
                        onFavorite: () => widget.state.toggleFavorite(item.id),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
        const SizedBox(height: 18),
        const Text(
          'Colección incluida en la app: paisajes dibujados por CEOSMOS y audios originales, disponibles sin conexión.',
          style: TextStyle(color: Cosmos.muted, fontSize: 12),
        ),
        const SizedBox(height: 30),
        LibrarySection(state: widget.state),
      ],
    );
  }
}

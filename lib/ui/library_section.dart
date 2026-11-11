import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_state.dart';
import '../core/media_cache.dart';
import '../data/api_client.dart';
import '../domain/models.dart';
import 'theme.dart';
import 'widgets.dart';

/// Extrae el id de un video de YouTube (enlace o id directo).
String? youtubeId(String entrada) {
  final t = entrada.trim();
  if (RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(t)) return t;
  final uri = Uri.tryParse(t);
  if (uri == null) return null;
  String? id;
  if (uri.host.endsWith('youtu.be')) {
    id = uri.pathSegments.isEmpty ? null : uri.pathSegments.first;
  } else if (uri.host.contains('youtube.com')) {
    id = uri.queryParameters['v'] ??
        (uri.pathSegments.length >= 2 && ['shorts', 'embed'].contains(uri.pathSegments.first)
            ? uri.pathSegments[1]
            : null);
  }
  return id != null && RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(id) ? id : null;
}

/// Imagen descargada bajo demanda y guardada en la caché LRU local.
class CachedImage extends StatefulWidget {
  const CachedImage({super.key, required this.url, this.height = 120});
  final String url;
  final double height;
  @override
  State<CachedImage> createState() => _CachedImageState();
}

class _CachedImageState extends State<CachedImage> {
  late Future<Uint8List> _bytes = MediaCache.instance.imagen(widget.url);

  @override
  void didUpdateWidget(CachedImage old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url) _bytes = MediaCache.instance.imagen(widget.url);
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: widget.height,
    width: double.infinity,
    child: FutureBuilder<Uint8List>(
      future: _bytes,
      builder: (context, snap) {
        if (snap.hasData) {
          return Image.memory(
            snap.data!,
            fit: BoxFit.cover,
            cacheWidth: 600, // decodifica a tamaño de miniatura (memoria)
            gaplessPlayback: true,
            errorBuilder: (_, _, _) => const _Falla('Imagen no válida'),
          );
        }
        if (snap.hasError) return _Falla('${snap.error}');
        return const ColoredBox(
          color: Cosmos.elevated,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      },
    ),
  );
}

class _Falla extends StatelessWidget {
  const _Falla(this.texto);
  final String texto;
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Cosmos.elevated,
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Text(texto, textAlign: TextAlign.center, style: const TextStyle(color: Cosmos.muted, fontSize: 11)),
      ),
    ),
  );
}

/// Biblioteca personal del usuario (`/api/media`): imágenes y videos de YouTube.
class LibrarySection extends StatelessWidget {
  const LibrarySection({super.key, required this.state});
  final AppState state;

  void _aviso(BuildContext context, String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  Future<void> _agregar(BuildContext context) async {
    final r = await showDialog<(String, String, String)>(
      context: context,
      builder: (_) => const _AgregarDialog(),
    );
    if (r == null || !context.mounted) return;
    final (tipo, e, t) = r;
    try {
      await state.addLibraryItem(
        type: tipo,
        externalId: tipo == 'YOUTUBE' ? youtubeId(e) : null,
        url: tipo == 'IMAGE' ? e : null,
        title: t,
      );
    } on ApiException catch (err) {
      if (context.mounted) _aviso(context, err.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = state.workspace.library;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('Mi biblioteca', style: Theme.of(context).textTheme.titleLarge)),
            TextButton.icon(
              onPressed: () => _agregar(context),
              icon: const Icon(Icons.add),
              label: const Text('Agregar'),
            ),
          ],
        ),
        const Text(
          'Tus imágenes y videos guardados en tu cuenta. Las imágenes se guardan en una caché local de hasta 150 MB.',
          style: TextStyle(color: Cosmos.muted, fontSize: 12),
        ),
        const SizedBox(height: 14),
        if (state.loadingData && items.isEmpty)
          const LinearProgressIndicator()
        else if (items.isEmpty)
          const EmptyState(
            icon: Icons.photo_library_outlined,
            title: 'Tu biblioteca está vacía',
            message: 'Agrega una imagen o un video que te ayude a concentrarte.',
          )
        else
          SizedBox(
            height: 216,
            // ListView.builder: solo se construyen (y descargan) las tarjetas visibles.
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (context, i) => _Tarjeta(state: state, item: items[i]),
            ),
          ),
      ],
    );
  }
}

class _Tarjeta extends StatelessWidget {
  const _Tarjeta({required this.state, required this.item});
  final AppState state;
  final LibraryItem item;

  @override
  Widget build(BuildContext context) {
    final favorito = state.workspace.favorites.contains(item.contentKey);
    return SizedBox(
      width: 220,
      child: Panel(
        padding: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.imageUrl != null) CachedImage(url: item.imageUrl!, height: 120),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 6, 0),
                child: Row(
                  children: [
                    Icon(item.isYoutube ? Icons.smart_display_outlined : Icons.image_outlined,
                        size: 16, color: Cosmos.lavender),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.title ?? (item.isYoutube ? 'Video de YouTube' : 'Imagen'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    tooltip: favorito ? 'Quitar de favoritos' : 'Agregar a favoritos',
                    onPressed: () => state.toggleFavorite(item.contentKey),
                    icon: Icon(favorito ? Icons.favorite : Icons.favorite_border, color: Cosmos.lavender, size: 20),
                  ),
                  if (item.openUrl != null)
                    IconButton(
                      tooltip: 'Abrir',
                      onPressed: () => launchUrl(item.openUrl!, mode: LaunchMode.externalApplication),
                      icon: const Icon(Icons.open_in_new, size: 20),
                    ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Eliminar de mi biblioteca',
                    onPressed: () async {
                      try {
                        await state.deleteLibraryItem(item);
                      } on ApiException catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                        }
                      }
                    },
                    icon: const Icon(Icons.delete_outline, size: 20),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgregarDialog extends StatefulWidget {
  const _AgregarDialog();
  @override
  State<_AgregarDialog> createState() => _AgregarDialogState();
}

class _AgregarDialogState extends State<_AgregarDialog> {
  final _form = GlobalKey<FormState>();
  final _enlace = TextEditingController();
  final _titulo = TextEditingController();
  var _tipo = 'IMAGE';

  @override
  void dispose() {
    _enlace.dispose();
    _titulo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Agregar a mi biblioteca'),
    content: Form(
      key: _form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'IMAGE', label: Text('Imagen'), icon: Icon(Icons.image_outlined)),
              ButtonSegment(value: 'YOUTUBE', label: Text('YouTube'), icon: Icon(Icons.smart_display_outlined)),
            ],
            selected: {_tipo},
            onSelectionChanged: (s) => setState(() => _tipo = s.first),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _enlace,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              labelText: _tipo == 'IMAGE' ? 'URL de la imagen (JPEG o WebP)' : 'Enlace o id del video',
            ),
            validator: (v) {
              final t = v?.trim() ?? '';
              if (_tipo == 'YOUTUBE') return youtubeId(t) == null ? 'Enlace de YouTube no válido.' : null;
              final uri = Uri.tryParse(t);
              return uri == null || !uri.isScheme('https') || uri.host.isEmpty ? 'Usa una URL https.' : null;
            },
          ),
          TextFormField(
            controller: _titulo,
            maxLength: 80,
            decoration: const InputDecoration(labelText: 'Título (opcional)'),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
      FilledButton(
        onPressed: () {
          if (_form.currentState!.validate()) {
            Navigator.pop(context, (_tipo, _enlace.text.trim(), _titulo.text.trim()));
          }
        },
        child: const Text('Agregar'),
      ),
    ],
  );
}

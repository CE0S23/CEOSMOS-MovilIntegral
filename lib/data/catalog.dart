import '../domain/models.dart';

const catalog = <MediaItem>[
  MediaItem(
    id: 'orbit',
    title: 'Órbita tranquila',
    subtitle: 'Texturas ambientales · Bucle de 30 s',
    mode: FocusMode.focus,
    kind: MediaKind.audio,
    scene: 0,
    audioAsset: 'audio/orbit.mp3',
  ),
  MediaItem(
    id: 'forest',
    title: 'Bosque en calma',
    subtitle: 'Ambiente sintético · Bucle de 30 s',
    mode: FocusMode.relax,
    kind: MediaKind.audio,
    scene: 1,
    audioAsset: 'audio/forest.mp3',
  ),
  MediaItem(
    id: 'dawn',
    title: 'Un nuevo horizonte',
    subtitle: 'Acordes suaves · Bucle de 30 s',
    mode: FocusMode.inspire,
    kind: MediaKind.audio,
    scene: 2,
    audioAsset: 'audio/dawn.mp3',
  ),
  MediaItem(
    id: 'nebula',
    title: 'Entre nebulosas',
    subtitle: 'Paisaje generativo · Espacio',
    mode: FocusMode.focus,
    kind: MediaKind.image,
    scene: 3,
  ),
  MediaItem(
    id: 'ocean',
    title: 'Respira con el océano',
    subtitle: 'Paisaje generativo · Naturaleza',
    mode: FocusMode.relax,
    kind: MediaKind.image,
    scene: 4,
  ),
  MediaItem(
    id: 'mountains',
    title: 'Más allá de la cima',
    subtitle: 'Paisaje generativo · Inspiración',
    mode: FocusMode.inspire,
    kind: MediaKind.image,
    scene: 5,
  ),
];

const reflections = [
  'Dale espacio a una sola idea. Lo demás puede esperar.',
  'Una pausa también puede ser parte del progreso.',
  'No necesitas hacerlo todo hoy. Empieza por lo importante.',
  'La creatividad comienza cuando te permites explorar.',
];

String normalized(String input) {
  var result = input.toLowerCase().trim();
  const accents = {'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u'};
  accents.forEach((key, value) => result = result.replaceAll(key, value));
  return result;
}

List<MediaItem> filterCatalog({
  String query = '',
  FocusMode? mode,
  MediaKind? kind,
  Set<String>? favorites,
}) {
  final words = normalized(
    query,
  ).split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  return catalog.where((item) {
    final text = normalized(
      '${item.title} ${item.subtitle} ${item.mode.label}',
    );
    return (mode == null || item.mode == mode) &&
        (kind == null || item.kind == kind) &&
        (favorites == null || favorites.contains(item.id)) &&
        words.every(text.contains);
  }).toList();
}

enum FocusMode {
  focus('Concentración', 'FOCUS'),
  relax('Relajación', 'RELAX'),
  inspire('Inspiración', 'INSPIRE');

  const FocusMode(this.label, this.apiValue);
  final String label;

  /// Valor del enum FocusMode del backend.
  final String apiValue;

  static FocusMode fromApi(String value) =>
      values.firstWhere((m) => m.apiValue == value, orElse: () => focus);
}

enum MediaKind { audio, image }

enum UserRole { user, admin }

DateTime _fecha(Object? valor) =>
    DateTime.tryParse('$valor')?.toLocal() ?? DateTime.fromMillisecondsSinceEpoch(0);

class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.username,
    this.role = UserRole.user,
    this.emailVerified = true,
    this.preferredMinutes = 25,
    this.createdAt,
  });

  /// Respuesta de `GET /api/users/me`.
  factory AppUser.fromJson(Map<String, dynamic> json) {
    final prefs = json['preferences'];
    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String,
      username: json['username'] as String,
      role: json['role'] == 'ADMIN' ? UserRole.admin : UserRole.user,
      emailVerified: json['emailVerified'] as bool? ?? true,
      preferredMinutes: prefs is Map ? (prefs['flowTimeDefault'] as num?)?.toInt() ?? 25 : 25,
      createdAt: json['createdAt'] == null ? null : _fecha(json['createdAt']),
    );
  }

  final String id;
  final String email;
  final String username;
  final UserRole role;
  final bool emailVerified;
  final int preferredMinutes;
  final DateTime? createdAt;
  bool get isAdmin => role == UserRole.admin;

  AppUser copyWith({String? username, int? preferredMinutes}) => AppUser(
    id: id,
    email: email,
    username: username ?? this.username,
    role: role,
    emailVerified: emailVerified,
    preferredMinutes: preferredMinutes ?? this.preferredMinutes,
    createdAt: createdAt,
  );
}

/// Sesión de autenticación (distinta de FocusSession). El token JWT lo emite
/// la API de CEOSMOS y se guarda en el almacenamiento seguro del sistema.
class AuthSession {
  const AuthSession({required this.user, required this.token});
  final AppUser user;
  final String token;
}

/// Contenido incluido en la app (audios propios y paisajes dibujados).
class MediaItem {
  const MediaItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.mode,
    required this.kind,
    required this.scene,
    this.audioAsset,
  });
  final String id;
  final String title;
  final String subtitle;
  final FocusMode mode;
  final MediaKind kind;
  final int scene;
  final String? audioAsset;
}

/// Elemento de la biblioteca personal (`MediaItem` del backend).
class LibraryItem {
  const LibraryItem({
    required this.id,
    required this.type,
    this.externalId,
    this.url,
    this.title,
    this.thumbnail,
  });

  factory LibraryItem.fromJson(Map<String, dynamic> json) => LibraryItem(
    id: json['id'] as String,
    type: json['type'] as String,
    externalId: json['externalId'] as String?,
    url: json['url'] as String?,
    title: json['title'] as String?,
    thumbnail: json['thumbnail'] as String?,
  );

  final String id;

  /// `YOUTUBE` o `IMAGE`.
  final String type;
  final String? externalId, url, title, thumbnail;
  bool get isYoutube => type == 'YOUTUBE';

  /// Clave usada en favoritos y sesiones de enfoque.
  String get contentKey => 'media:$id';

  /// Imagen a mostrar (JPEG/WebP): la propia imagen o la miniatura de YouTube.
  String? get imageUrl => isYoutube
      ? (thumbnail ?? 'https://img.youtube.com/vi/$externalId/hqdefault.jpg')
      : (thumbnail ?? url);

  Uri? get openUrl => isYoutube
      ? Uri.parse('https://www.youtube.com/watch?v=$externalId')
      : (url == null ? null : Uri.tryParse(url!));
}

class FocusSession {
  const FocusSession({
    required this.id,
    required this.contentKey,
    required this.mode,
    required this.startedAt,
    required this.endedAt,
    required this.durationSeconds,
    required this.targetMinutes,
    required this.completed,
    this.metadata = const {},
    this.synced = true,
  });

  factory FocusSession.fromJson(Map<String, dynamic> json) => FocusSession(
    id: json['id'] as String,
    contentKey: json['contentKey'] as String,
    mode: FocusMode.fromApi(json['mode'] as String),
    startedAt: _fecha(json['startedAt']),
    endedAt: _fecha(json['endedAt']),
    durationSeconds: (json['durationSeconds'] as num).toInt(),
    targetMinutes: (json['targetMinutes'] as num).toInt(),
    completed: json['completed'] as bool? ?? false,
    metadata: (json['metadata'] as Map?)?.cast<String, dynamic>() ?? const {},
  );

  final String id, contentKey;
  final FocusMode mode;
  final DateTime startedAt, endedAt;
  final int durationSeconds, targetMinutes;
  final bool completed;

  /// Datos variables (JSONB), p. ej. métricas del wearable.
  final Map<String, dynamic> metadata;

  /// false mientras no la confirme el servidor.
  final bool synced;

  Map<String, Object?> toJson() => {
    'contentKey': contentKey,
    'mode': mode.apiValue,
    'startedAt': startedAt.toUtc().toIso8601String(),
    'endedAt': endedAt.toUtc().toIso8601String(),
    'durationSeconds': durationSeconds,
    'targetMinutes': targetMinutes,
    'completed': completed,
    if (metadata.isNotEmpty) 'metadata': metadata,
  };
}

class LinkedDevice {
  const LinkedDevice({
    required this.id,
    required this.name,
    required this.type,
    required this.transport,
    required this.address,
    this.lastSeenAt,
  });

  factory LinkedDevice.fromJson(Map<String, dynamic> json) => LinkedDevice(
    id: json['id'] as String,
    name: json['name'] as String,
    type: json['type'] as String,
    transport: json['transport'] as String,
    address: json['address'] as String,
    lastSeenAt: json['lastSeenAt'] == null ? null : _fecha(json['lastSeenAt']),
  );

  final String id, name;

  /// `WEARABLE` o `TV`.
  final String type;

  /// `TCP` (primario) o `BLE` (respaldo).
  final String transport;

  /// host:puerto (TCP) o MAC (BLE).
  final String address;
  final DateTime? lastSeenAt;
}

/// Datos del usuario autenticado traídos de la API.
class UserWorkspace {
  final Set<String> favorites = {};
  final List<FocusSession> history = [];
  final List<LinkedDevice> devices = [];
  final List<LibraryItem> library = [];
  int preferredMinutes = 25;
}

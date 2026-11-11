enum FocusMode {
  focus('Concentración', 'focus'),
  relax('Relajación', 'relax'),
  inspire('Inspiración', 'inspire');

  const FocusMode(this.label, this.apiValue);
  final String label;
  final String apiValue;
}

enum MediaKind { audio, image }

class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.username,
  });
  final String id;
  final String email;
  final String username;
  Map<String, Object> toJson() => {
    'id': id,
    'email': email,
    'username': username,
    'role': 'USER',
  };
}

/// Separate from FocusSession: mirrors the web backend's authentication Session.
class AuthSession {
  const AuthSession({required this.user, required this.expiresAt});
  final AppUser user;
  final DateTime expiresAt;
  bool isExpired(DateTime now) => !now.isBefore(expiresAt);
}

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
  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'type': kind.name.toUpperCase(),
    'metadata': {'mode': mode.apiValue, 'scene': scene},
    'url': audioAsset,
  };
}

class FocusSession {
  const FocusSession({
    required this.id,
    required this.userId,
    required this.mediaId,
    required this.mode,
    required this.startedAt,
    required this.endedAt,
    required this.durationSeconds,
    required this.completed,
  });
  final String id, userId, mediaId;
  final FocusMode mode;
  final DateTime startedAt, endedAt;
  final int durationSeconds;
  final bool completed;
  Map<String, Object?> toJson() => {
    'id': id,
    'userId': userId,
    'mediaId': mediaId,
    'mode': mode.apiValue,
    'startedAt': startedAt.toIso8601String(),
    'endedAt': endedAt.toIso8601String(),
    'durationSeconds': durationSeconds,
    'metadata': {'completed': completed, 'source': 'local-demo'},
  };
}

class LinkedDevice {
  const LinkedDevice({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.linkedAt,
  });
  final String id, userId, name, type;
  final DateTime linkedAt;
  Map<String, Object?> toJson() => {
    'id': id,
    'userId': userId,
    'name': name,
    'type': type,
    'linkedAt': linkedAt.toIso8601String(),
    'configuration': {'transport': 'simulation'},
  };
}

class UserWorkspace {
  final Set<String> favorites = {};
  final List<FocusSession> history = [];
  final List<LinkedDevice> devices = [];
  int preferredMinutes = 25;
}

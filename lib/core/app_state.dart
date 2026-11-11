import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/auth_repository.dart';
import '../domain/models.dart';

class AppState extends ChangeNotifier {
  AppState({
    AuthRepository? auth,
    DateTime Function()? now,
    bool startTicker = true,
  }) : auth = auth ?? MemoryAuthRepository(),
       _now = now ?? DateTime.now {
    if (startTicker) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) => tick());
    }
  }
  final AuthRepository auth;
  final DateTime Function() _now;
  Timer? _ticker;
  AuthSession? authentication;
  String? notice;
  final Map<String, UserWorkspace> _workspaces = {};
  AppUser? get user => authentication?.user;
  UserWorkspace get workspace =>
      _workspaces.putIfAbsent(user!.id, UserWorkspace.new);
  MediaItem? currentMedia;
  DateTime? _startedAt, _runningSince;
  Duration _accumulated = Duration.zero;
  int targetMinutes = 25;
  bool get running => _runningSince != null;
  bool get hasSession => currentMedia != null;
  Duration get elapsed =>
      _accumulated +
      (_runningSince == null
          ? Duration.zero
          : _now().difference(_runningSince!));
  Duration get remaining {
    final seconds = targetMinutes * 60 - elapsed.inSeconds;
    return Duration(seconds: seconds.clamp(0, targetMinutes * 60));
  }

  double get progress =>
      (elapsed.inMilliseconds / (targetMinutes * 60000)).clamp(0.0, 1.0);

  void acceptSession(AuthSession session) {
    authentication = session;
    notice = null;
    targetMinutes = workspace.preferredMinutes;
    notifyListeners();
  }

  Future<void> signOut() async {
    if (hasSession) finishSession();
    await auth.logout();
    authentication = null;
    notifyListeners();
  }

  void toggleFavorite(String id) {
    if (!workspace.favorites.remove(id)) workspace.favorites.add(id);
    notifyListeners();
  }

  void setPreferredMinutes(int minutes) {
    if (![5, 15, 25, 45].contains(minutes)) throw ArgumentError.value(minutes);
    workspace.preferredMinutes = minutes;
    notifyListeners();
  }

  void startSession(MediaItem item, int minutes) {
    if (user == null) throw StateError('Inicia sesión primero.');
    if (![5, 15, 25, 45].contains(minutes)) throw ArgumentError.value(minutes);
    if (hasSession) finishSession();
    currentMedia = item;
    targetMinutes = minutes;
    _accumulated = Duration.zero;
    _startedAt = _now();
    _runningSince = _startedAt;
    notifyListeners();
  }

  void togglePause() {
    if (!hasSession) return;
    if (running) {
      _accumulated = elapsed;
      _runningSince = null;
    } else {
      _runningSince = _now();
    }
    notifyListeners();
  }

  void finishSession({bool completed = false}) {
    if (currentMedia == null) return;
    workspace.history.insert(
      0,
      FocusSession(
        id: '${_now().microsecondsSinceEpoch}-${workspace.history.length}',
        userId: user!.id,
        mediaId: currentMedia!.id,
        mode: currentMedia!.mode,
        startedAt: _startedAt!,
        endedAt: _now(),
        durationSeconds: elapsed.inSeconds.clamp(0, targetMinutes * 60),
        completed: completed,
      ),
    );
    currentMedia = null;
    _runningSince = null;
    _startedAt = null;
    _accumulated = Duration.zero;
    notifyListeners();
  }

  void toggleDevice(String type) {
    final devices = workspace.devices;
    final index = devices.indexWhere((d) => d.type == type);
    if (index >= 0) {
      devices.removeAt(index);
    } else {
      devices.add(
        LinkedDevice(
          id: 'demo-$type',
          userId: user!.id,
          name: type == 'wearable' ? 'CEOSMOS Band' : 'CEOSMOS TV',
          type: type,
          linkedAt: _now(),
        ),
      );
    }
    notifyListeners();
  }

  void tick() {
    if (authentication?.isExpired(_now()) ?? false) {
      if (hasSession) finishSession();
      authentication = null;
      notice = 'Tu sesión local expiró. Vuelve a entrar.';
      notifyListeners();
      return;
    }
    if (hasSession && remaining == Duration.zero) {
      finishSession(completed: true);
    } else if (running) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

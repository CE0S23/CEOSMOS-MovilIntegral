import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/api_client.dart';
import '../data/auth_repository.dart';
import '../data/ceosmos_repository.dart';
import '../data/token_store.dart';
import '../domain/models.dart';
import 'config.dart';
import 'wearable.dart';

enum AuthStatus { restoring, signedOut, signedIn }

/// Duraciones de sesión de enfoque que ofrece la app (el servidor admite 5–180).
const sessionMinutes = [5, 15, 25, 45, 60];

/// Estado global: sesión de acceso, datos del usuario (API de CEOSMOS),
/// temporizador de enfoque y wearable.
class AppState extends ChangeNotifier {
  AppState({
    required this.auth,
    required this.data,
    WearableClient? wearable,
    DateTime Function()? now,
    bool startTicker = true,
  }) : wearable = wearable ?? WearableClient(),
       _now = now ?? DateTime.now {
    auth.api.onUnauthorized = _sesionVencida;
    if (startTicker) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) => tick());
    }
  }

  /// Configuración real: API de CEOSMOS y token en almacenamiento seguro.
  factory AppState.production() {
    final api = ApiClient(baseUrl: AppConfig.apiBaseUrl);
    return AppState(
      auth: AuthRepository(api, SecureTokenStore()),
      data: CeosmosRepository(api),
    );
  }

  final AuthRepository auth;
  final CeosmosRepository data;
  final WearableClient wearable;
  final DateTime Function() _now;
  Timer? _ticker;
  bool _disposed = false;

  AuthStatus status = AuthStatus.restoring;
  AuthSession? authentication;
  AppUser? get user => authentication?.user;

  /// Aviso pendiente de mostrar (errores de red, sesión vencida, etc.).
  String? notice;
  String? takeNotice() {
    final n = notice;
    notice = null;
    return n;
  }

  UserWorkspace workspace = UserWorkspace();
  bool loadingData = false;
  String? dataError;
  final List<FocusSession> _pendientes = [];

  MediaItem? currentMedia;
  DateTime? _startedAt, _runningSince;
  Duration _accumulated = Duration.zero;
  int targetMinutes = 25;
  bool get running => _runningSince != null;
  bool get hasSession => currentMedia != null;
  Duration get elapsed =>
      _accumulated +
      (_runningSince == null ? Duration.zero : _now().difference(_runningSince!));
  Duration get remaining {
    final seconds = targetMinutes * 60 - elapsed.inSeconds;
    return Duration(seconds: seconds.clamp(0, targetMinutes * 60));
  }

  double get progress =>
      (elapsed.inMilliseconds / (targetMinutes * 60000)).clamp(0.0, 1.0);

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Sesión de acceso
  // ---------------------------------------------------------------------------

  /// Al abrir la app: recupera el token guardado y valida con `/users/me`.
  Future<void> restore() async {
    status = AuthStatus.restoring;
    _changed();
    try {
      final session = await auth.restore();
      if (session == null) {
        status = AuthStatus.signedOut;
        _changed();
        return;
      }
      await acceptSession(session);
    } on ApiException catch (e) {
      status = AuthStatus.signedOut;
      notice = e.message;
      _changed();
    }
  }

  Future<void> acceptSession(AuthSession session) async {
    authentication = session;
    status = AuthStatus.signedIn;
    workspace = UserWorkspace()..preferredMinutes = session.user.preferredMinutes;
    targetMinutes = _minutosValidos(session.user.preferredMinutes);
    notice = null;
    _changed();
    await loadWorkspace();
  }

  int _minutosValidos(int m) => sessionMinutes.contains(m) ? m : 25;

  /// Trae favoritos, historial, dispositivos y biblioteca en paralelo.
  Future<void> loadWorkspace() async {
    if (user == null) return;
    loadingData = true;
    dataError = null;
    _changed();
    try {
      await _enviarPendientes();
      final r = await Future.wait([
        data.favorites(),
        data.focusSessions(),
        data.devices(),
        data.library(),
      ]);
      if (user == null) return;
      workspace.favorites
        ..clear()
        ..addAll(r[0] as Set<String>);
      workspace.history
        ..clear()
        ..addAll(_pendientes)
        ..addAll(r[1] as List<FocusSession>);
      workspace.devices
        ..clear()
        ..addAll(r[2] as List<LinkedDevice>);
      workspace.library
        ..clear()
        ..addAll(r[3] as List<LibraryItem>);
    } on ApiException catch (e) {
      dataError = e.message;
    } finally {
      loadingData = false;
      _changed();
    }
  }

  void _sesionVencida() {
    if (authentication == null) return;
    _cerrarLocal();
    notice = 'Tu sesión expiró o se cerró en otro dispositivo. Vuelve a iniciar sesión.';
    unawaited(auth.tokens.clear());
    auth.api.token = null;
    _changed();
  }

  void _cerrarLocal() {
    if (hasSession) _descartarSesionActiva();
    unawaited(wearable.desconectar());
    authentication = null;
    status = AuthStatus.signedOut;
    workspace = UserWorkspace();
    _pendientes.clear();
  }

  Future<void> signOut() async {
    if (hasSession) await finishSession();
    await auth.logout();
    _cerrarLocal();
    _changed();
  }

  // ---------------------------------------------------------------------------
  // Perfil y preferencias
  // ---------------------------------------------------------------------------

  Future<void> updateUsername(String username) async {
    final updated = await data.updateUsername(username);
    authentication = AuthSession(user: updated, token: authentication!.token);
    _changed();
  }

  Future<void> setPreferredMinutes(int minutes) async {
    if (!sessionMinutes.contains(minutes)) throw ArgumentError.value(minutes);
    final anterior = workspace.preferredMinutes;
    workspace.preferredMinutes = minutes;
    _changed();
    try {
      await data.updatePreferredMinutes(minutes);
    } on ApiException catch (e) {
      workspace.preferredMinutes = anterior;
      notice = 'No se guardó la preferencia: ${e.message}';
      _changed();
    }
  }

  Future<void> deleteAccount() async {
    await data.deleteAccount();
    await auth.tokens.clear();
    auth.api.token = null;
    _cerrarLocal();
    notice = 'Tu cuenta se eliminó.';
    _changed();
  }

  // ---------------------------------------------------------------------------
  // Favoritos (actualización optimista, se revierte si el servidor falla)
  // ---------------------------------------------------------------------------

  Future<void> toggleFavorite(String key) async {
    final agregar = !workspace.favorites.contains(key);
    agregar ? workspace.favorites.add(key) : workspace.favorites.remove(key);
    _changed();
    try {
      agregar ? await data.addFavorite(key) : await data.removeFavorite(key);
    } on ApiException catch (e) {
      agregar ? workspace.favorites.remove(key) : workspace.favorites.add(key);
      notice = 'No se actualizó el favorito: ${e.message}';
      _changed();
    }
  }

  // ---------------------------------------------------------------------------
  // Sesión de enfoque
  // ---------------------------------------------------------------------------

  void startSession(MediaItem item, int minutes) {
    if (user == null) throw StateError('Inicia sesión primero.');
    if (!sessionMinutes.contains(minutes)) throw ArgumentError.value(minutes);
    if (hasSession) unawaited(finishSession());
    currentMedia = item;
    targetMinutes = minutes;
    _accumulated = Duration.zero;
    _startedAt = _now();
    _runningSince = _startedAt;
    wearable.marcarInicio();
    _changed();
  }

  void togglePause() {
    if (!hasSession) return;
    if (running) {
      _accumulated = elapsed;
      _runningSince = null;
    } else {
      _runningSince = _now();
    }
    _changed();
  }

  void _descartarSesionActiva() {
    currentMedia = null;
    _runningSince = null;
    _startedAt = null;
    _accumulated = Duration.zero;
  }

  /// Guarda la sesión en el historial del servidor. Si no hay red, queda
  /// marcada como pendiente y se reenvía en la siguiente carga de datos.
  Future<void> finishSession({bool completed = false}) async {
    final media = currentMedia;
    if (media == null || user == null) return;
    final metadata = <String, dynamic>{
      'source': 'ceosmos-movil',
      'kind': media.kind.name,
      ...wearable.resumenSesion(),
    };
    final local = FocusSession(
      id: 'pendiente-${_now().microsecondsSinceEpoch}',
      contentKey: media.id,
      mode: media.mode,
      startedAt: _startedAt!,
      endedAt: _now(),
      durationSeconds: elapsed.inSeconds.clamp(0, targetMinutes * 60),
      targetMinutes: targetMinutes,
      completed: completed,
      metadata: metadata,
      synced: false,
    );
    _descartarSesionActiva();
    workspace.history.insert(0, local);
    _changed();
    try {
      final saved = await data.saveFocusSession(local);
      final i = workspace.history.indexOf(local);
      if (i >= 0) workspace.history[i] = saved;
    } on ApiException catch (e) {
      if (e.unauthorized) return;
      _pendientes.add(local);
      notice = 'La sesión se guardará cuando vuelva la conexión (${e.message})';
    }
    _changed();
  }

  Future<void> _enviarPendientes() async {
    for (final p in List.of(_pendientes)) {
      await data.saveFocusSession(p);
      _pendientes.remove(p);
    }
  }

  int get pendingSessions => _pendientes.length;

  // ---------------------------------------------------------------------------
  // Dispositivos (wearable por TCP/IP)
  // ---------------------------------------------------------------------------

  Future<LinkedDevice> linkWearable(String name, String address) async {
    final device = await data.linkDevice(name: name, address: address);
    workspace.devices.add(device);
    _changed();
    return device;
  }

  Future<void> unlinkDevice(LinkedDevice device) async {
    if (wearable.deviceId == device.id) await wearable.desconectar();
    await data.unlinkDevice(device.id);
    workspace.devices.removeWhere((d) => d.id == device.id);
    _changed();
  }

  /// Conecta por TCP con el dispositivo y registra la última conexión.
  Future<void> connectWearable(LinkedDevice device) async {
    final sep = device.address.lastIndexOf(':');
    final host = device.address.substring(0, sep);
    final port = int.parse(device.address.substring(sep + 1));
    await wearable.conectar(deviceId: device.id, host: host, port: port);
    if (wearable.estado == WearableEstado.conectado) {
      try {
        final updated = await data.markDeviceSeen(device.id);
        final i = workspace.devices.indexWhere((d) => d.id == device.id);
        if (i >= 0) workspace.devices[i] = updated;
        _changed();
      } on ApiException {
        // La conexión con el dispositivo sigue siendo válida.
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Biblioteca multimedia
  // ---------------------------------------------------------------------------

  Future<void> addLibraryItem({
    required String type,
    String? externalId,
    String? url,
    String? title,
  }) async {
    final item = await data.addLibraryItem(
      type: type,
      externalId: externalId,
      url: url,
      title: title,
    );
    workspace.library.insert(0, item);
    _changed();
  }

  Future<void> deleteLibraryItem(LibraryItem item) async {
    await data.deleteLibraryItem(item.id);
    workspace.library.removeWhere((i) => i.id == item.id);
    workspace.favorites.remove(item.contentKey);
    _changed();
  }

  void tick() {
    if (hasSession && remaining == Duration.zero) {
      unawaited(finishSession(completed: true));
    } else if (running) {
      _changed();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _ticker?.cancel();
    wearable.dispose();
    super.dispose();
  }
}

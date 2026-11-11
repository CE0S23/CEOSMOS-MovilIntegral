import '../domain/models.dart';
import 'api_client.dart';

List<Map<String, dynamic>> _lista(Object? json) =>
    (json as List? ?? const []).cast<Map>().map((m) => m.cast<String, dynamic>()).toList();

/// Datos del usuario autenticado en la API de CEOSMOS (PostgreSQL).
class CeosmosRepository {
  CeosmosRepository(this.api);
  final ApiClient api;

  // ---- Perfil y preferencias (/users) ----
  Future<AppUser> updateUsername(String username) async {
    await api.patch('/users/profile', {'username': username.trim()});
    return AppUser.fromJson((await api.get('/users/me')) as Map<String, dynamic>);
  }

  Future<void> updatePreferredMinutes(int minutes) =>
      api.patch('/users/preferences', {'flowTimeDefault': minutes});

  Future<List<Map<String, dynamic>>> activeSessions() async =>
      _lista(await api.get('/users/me/sessions'));

  Future<void> deleteAccount() => api.delete('/users/me');

  // ---- Favoritos (/favorites) ----
  Future<Set<String>> favorites() async =>
      _lista(await api.get('/favorites')).map((f) => f['contentKey'] as String).toSet();

  Future<void> addFavorite(String key) => api.put('/favorites/${Uri.encodeComponent(key)}');
  Future<void> removeFavorite(String key) =>
      api.delete('/favorites/${Uri.encodeComponent(key)}');

  // ---- Sesiones de enfoque (/focus-sessions) ----
  Future<List<FocusSession>> focusSessions({int limit = 50}) async =>
      _lista(await api.get('/focus-sessions', query: {'limit': '$limit'}))
          .map(FocusSession.fromJson)
          .toList();

  Future<FocusSession> saveFocusSession(FocusSession session) async =>
      FocusSession.fromJson(
        (await api.post('/focus-sessions', session.toJson())) as Map<String, dynamic>,
      );

  // ---- Dispositivos (/devices) ----
  Future<List<LinkedDevice>> devices() async =>
      _lista(await api.get('/devices')).map(LinkedDevice.fromJson).toList();

  Future<LinkedDevice> linkDevice({
    required String name,
    required String address,
    String type = 'WEARABLE',
    String transport = 'TCP',
  }) async => LinkedDevice.fromJson(
    (await api.post('/devices', {
      'name': name.trim(),
      'type': type,
      'transport': transport,
      'address': address.trim(),
    })) as Map<String, dynamic>,
  );

  Future<LinkedDevice> markDeviceSeen(String id) async => LinkedDevice.fromJson(
    (await api.patch('/devices/$id', {'seen': true})) as Map<String, dynamic>,
  );

  Future<void> unlinkDevice(String id) => api.delete('/devices/$id');

  // ---- Biblioteca multimedia (/media) ----
  Future<List<LibraryItem>> library() async =>
      _lista(await api.get('/media')).map(LibraryItem.fromJson).toList();

  Future<LibraryItem> addLibraryItem({
    required String type,
    String? externalId,
    String? url,
    String? title,
  }) async => LibraryItem.fromJson(
    (await api.post('/media', {
      'type': type,
      'externalId': ?externalId,
      'url': ?url,
      if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
    })) as Map<String, dynamic>,
  );

  Future<void> deleteLibraryItem(String id) => api.delete('/media/$id');

  // ---- Administración (/admin, solo ADMIN; el servidor lo vuelve a validar) ----
  Future<List<Map<String, dynamic>>> adminUsers() async =>
      _lista(await api.get('/admin/users'));

  Future<void> adminSetActive(String id, bool active) =>
      api.patch('/admin/users/$id/status', {'active': active});

  Future<void> adminSetRole(String id, String role) =>
      api.patch('/admin/users/$id/role', {'role': role});

  Future<Map<String, dynamic>> adminAuditLog({int page = 1, int pageSize = 20}) async =>
      ((await api.get('/admin/audit-log', query: {
        'page': '$page',
        'pageSize': '$pageSize',
      })) as Map).cast<String, dynamic>();
}

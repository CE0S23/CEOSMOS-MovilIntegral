import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/media_cache.dart';
import '../data/api_client.dart';
import '../data/auth_repository.dart';
import '../data/catalog.dart';
import '../domain/models.dart';
import 'admin_screen.dart';
import 'theme.dart';
import 'widgets.dart';

/// Título legible de un contenido del historial o de favoritos.
String tituloContenido(AppState state, String key) {
  for (final m in catalog) {
    if (m.id == key) return m.title;
  }
  for (final l in state.workspace.library) {
    if (l.contentKey == key) return l.title ?? 'Elemento de mi biblioteca';
  }
  return 'Contenido que ya no está disponible';
}

String _fecha(DateTime t) =>
    '${t.day}/${t.month}/${t.year} · ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.state,
    required this.onFavorites,
    required this.onLogout,
  });
  final AppState state;
  final VoidCallback onFavorites, onLogout;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<List<Map<String, dynamic>>> _sesiones = widget.state.data.activeSessions();
  late Future<int> _cache = MediaCache.instance.tamano();

  AppState get state => widget.state;

  void _aviso(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _editarNombre() async {
    final valores = await showDialog<List<String>>(
      context: context,
      builder: (_) => FormDialog(
        title: 'Nombre de usuario',
        confirmLabel: 'Guardar',
        fields: [
          DialogField(
            'Nombre de usuario',
            initial: state.user!.username,
            maxLength: 30,
            validator: AuthRepository.validarUsuario,
          ),
        ],
      ),
    );
    final nuevo = valores?.first;
    if (nuevo == null || nuevo == state.user!.username) return;
    try {
      await state.updateUsername(nuevo);
      _aviso('Nombre actualizado.');
    } on ApiException catch (e) {
      _aviso(e.message);
    }
  }

  Future<void> _eliminarCuenta() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar tu cuenta?'),
        content: const Text(
          'Se borrarán de forma permanente tu cuenta, historial, favoritos, dispositivos y biblioteca. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Cosmos.peach),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar cuenta'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await state.deleteAccount();
    } on ApiException catch (e) {
      _aviso(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = state.user!;
    final workspace = state.workspace;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeading('Tu espacio', 'Cada pequeño momento cuenta.'),
        Panel(
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Cosmos.lavender,
                foregroundColor: Cosmos.background,
                child: Text(
                  user.username.characters.first.toUpperCase(),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.username, style: Theme.of(context).textTheme.titleLarge),
                    Text(user.email, style: const TextStyle(color: Cosmos.muted)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Tag(user.isAdmin ? 'Administrador' : 'Usuario', color: Cosmos.lavender),
                        if (user.emailVerified) const Tag('Correo verificado', color: Cosmos.mint),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Editar nombre de usuario',
                onPressed: _editarNombre,
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
        ),
        if (user.isAdmin) ...[
          const SizedBox(height: 16),
          Panel(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.admin_panel_settings_outlined, color: Cosmos.peach),
              title: const Text('Administración'),
              subtitle: const Text('Usuarios, roles, estado y bitácora'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => AdminScreen(state: state),
                  settings: const RouteSettings(name: '/admin'),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('A tu ritmo', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text('Duración predeterminada de tus sesiones', style: TextStyle(color: Cosmos.muted)),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: sessionMinutes
                    .map(
                      (minutes) => ChoiceChip(
                        label: Text('$minutes min'),
                        selected: workspace.preferredMinutes == minutes,
                        onSelected: (_) => state.setPreferredMinutes(minutes),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.favorite_outline, color: Cosmos.lavender),
                title: const Text('Mis favoritos'),
                subtitle: Text('${workspace.favorites.length} experiencias guardadas'),
                trailing: const Icon(Icons.chevron_right),
                onTap: widget.onFavorites,
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(child: Text('Tu historial', style: Theme.of(context).textTheme.titleLarge)),
            if (state.loadingData)
              const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
            else
              IconButton(
                tooltip: 'Actualizar historial',
                onPressed: state.loadWorkspace,
                icon: const Icon(Icons.refresh, size: 20),
              ),
            Text('${state.totalSessions} sesiones', style: const TextStyle(color: Cosmos.muted, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 14),
        if (state.dataError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(state.dataError!, style: const TextStyle(color: Cosmos.peach)),
          ),
        if (workspace.history.isEmpty && !state.loadingData)
          const EmptyState(
            icon: Icons.history_rounded,
            title: 'Tu primera sesión te espera',
            message: 'Cuando termines una sesión, encontrarás aquí tu tiempo y tu ambiente.',
          ),
        ...workspace.history.map((session) => _SesionTile(state: state, session: session)),
        // P12-O1: el historial llega por páginas de 20.
        if (state.historyHasMore)
          Center(
            child: state.loadingMoreHistory
                ? const Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(strokeWidth: 2))
                : TextButton.icon(
                    onPressed: state.loadMoreHistory,
                    icon: const Icon(Icons.expand_more_rounded),
                    label: const Text('Ver más sesiones'),
                  ),
          ),
        const SizedBox(height: 28),
        Text('Sesiones de acceso activas', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _sesiones,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.all(12),
                child: LinearProgressIndicator(),
              );
            }
            if (snap.hasError) {
              return Row(
                children: [
                  Expanded(child: Text('${snap.error}',style: const TextStyle(color: Cosmos.peach))),
                  TextButton(
                    onPressed: () => setState(() => _sesiones = state.data.activeSessions()),
                    child: const Text('Reintentar'),
                  ),
                ],
              );
            }
            final lista = snap.data!;
            return Panel(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              child: Column(
                children: [
                  for (final s in lista)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.devices_outlined, color: Cosmos.lavender),
                      title: Text(_fecha(DateTime.tryParse('${s['createdAt']}')?.toLocal() ?? DateTime.now())),
                      subtitle: Text('IP ${s['ipAddress'] ?? 'desconocida'}'),
                    ),
                  if (lista.isEmpty) const ListTile(title: Text('Sin sesiones registradas')),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        Panel(
          child: FutureBuilder<int>(
            future: _cache,
            builder: (context, snap) {
              final bytes = snap.data ?? 0;
              final usado = bytes < 1024 * 1024
                  ? '${(bytes / 1024).toStringAsFixed(0)} KB'
                  : '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
              return Row(
                children: [
                  const Icon(Icons.sd_storage_outlined, color: Cosmos.mint),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Caché de imágenes', style: TextStyle(fontWeight: FontWeight.w600)),
                        Text('$usado de 150 MB · se liberan primero las menos usadas',
                            style: const TextStyle(color: Cosmos.muted, fontSize: 12)),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await MediaCache.instance.limpiar();
                      setState(() => _cache = MediaCache.instance.tamano());
                    },
                    child: const Text('Vaciar'),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 22),
        OutlinedButton.icon(
          onPressed: () async {
            final logout = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('¿Cerrar sesión?'),
                content: Text(
                  state.hasSession
                      ? 'Tu sesión de enfoque terminará y se guardará en tu historial.'
                      : 'Se cerrará tu sesión en este dispositivo y en el servidor.',
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                  FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Cerrar sesión')),
                ],
              ),
            );
            if (logout == true) widget.onLogout();
          },
          icon: const Icon(Icons.logout, size: 18),
          label: const Text('Cerrar sesión'),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _eliminarCuenta,
          style: TextButton.styleFrom(foregroundColor: Cosmos.peach),
          icon: const Icon(Icons.delete_forever_outlined, size: 18),
          label: const Text('Eliminar mi cuenta'),
        ),
      ],
    );
  }
}

class _SesionTile extends StatelessWidget {
  const _SesionTile({required this.state, required this.session});
  final AppState state;
  final FocusSession session;

  @override
  Widget build(BuildContext context) {
    final wearable = session.metadata['wearable'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Panel(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(modeIcon(session.mode), color: modeColor(session.mode)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tituloContenido(state, session.contentKey), style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(_fecha(session.endedAt), style: const TextStyle(color: Cosmos.muted, fontSize: 12)),
                  if (wearable is Map)
                    Text(
                      '♥ ${wearable['avgHeartRate']} bpm promedio · ${wearable['samples']} lecturas',
                      style: const TextStyle(color: Cosmos.mint, fontSize: 12),
                    ),
                  if (!session.synced)
                    const Text('Pendiente de guardar en el servidor', style: TextStyle(color: Cosmos.peach, fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(clockLabel(Duration(seconds: session.durationSeconds)), style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  session.completed ? 'Completada' : 'Finalizada',
                  style: TextStyle(color: session.completed ? Cosmos.mint : Cosmos.muted, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

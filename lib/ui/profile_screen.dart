import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/media_cache.dart';
import '../core/sin_espacios.dart';
import '../data/api_client.dart';
import '../data/auth_repository.dart';
import '../data/catalog.dart';
import '../domain/models.dart';
import '../practicas/registro_practicas.dart' show Seccion;
import 'admin_screen.dart';
import 'alertas_ui.dart';
import 'funciones.dart';
import 'theme.dart';
import 'widgets.dart';
import '../core/plural.dart';

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
            inputFormatters: SinEspacios.formateadores(context),
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
            // Acción destructiva: rojo de error (distinto del guinda de marca).
            style: FilledButton.styleFrom(
              backgroundColor: CeosmosColores.error,
              foregroundColor: CeosmosColores.blanco,
            ),
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
                backgroundColor: CeosmosColores.cian,
                foregroundColor: CeosmosColores.guinda,
                child: Text(
                  user.username.characters.first.toUpperCase(),
                  style: context.texto.headlineSmall?.copyWith(
                    color: CeosmosColores.guinda,
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.username, style: context.texto.headlineSmall),
                    Text(user.email, style: TextStyle(color: context.paleta.textoSecundario)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Tag(user.isAdmin ? 'Administrador' : 'Usuario', color: context.paleta.enlace),
                        if (user.emailVerified) Tag('Correo verificado', color: context.paleta.exito),
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
              leading: Icon(Icons.admin_panel_settings_outlined, color: context.paleta.marca),
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
              Text('A tu ritmo', style: context.texto.headlineSmall),
              const SizedBox(height: 8),
              Text('Duración predeterminada de tus sesiones', style: TextStyle(color: context.paleta.textoSecundario)),
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
                leading: Icon(Icons.favorite_outline, color: context.paleta.enlace),
                title: const Text('Mis favoritos'),
                subtitle: Text(contar(workspace.favorites.length, 'experiencia guardada', 'experiencias guardadas')),
                trailing: const Icon(Icons.chevron_right),
                onTap: widget.onFavorites,
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        const GrupoFunciones(
          titulo: 'Cuenta y herramientas',
          descripcion: 'Protege tu acceso y usa las herramientas incluidas en CEOSMOS.',
          seccion: Seccion.perfil,
        ),
        const SizedBox(height: Espacio.m),
        InterruptorAlertas(state: state),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(child: Text('Tu historial', style: context.texto.headlineSmall)),
            if (state.loadingData)
              const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
            else
              IconButton(
                tooltip: 'Actualizar historial',
                onPressed: state.loadWorkspace,
                icon: const Icon(Icons.refresh, size: 20),
              ),
            Text(contar(state.totalSessions, 'sesión', 'sesiones'), style: context.texto.bodySmall),
          ],
        ),
        const SizedBox(height: 14),
        if (state.dataError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Aviso(state.dataError!),
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
        Text('Sesiones de acceso activas', style: context.texto.headlineSmall),
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
                  Expanded(child: Aviso('${snap.error}')),
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
                      leading: Icon(Icons.devices_outlined, color: context.paleta.enlace),
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
                  Icon(Icons.sd_storage_outlined, color: context.paleta.exito),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Caché de imágenes', style: context.texto.titleSmall),
                        Text('$usado de 150 MB · se liberan primero las menos usadas',
                            style: context.texto.bodySmall),
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
          style: TextButton.styleFrom(foregroundColor: context.paleta.error),
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
            Icon(modeIcon(session.mode), color: modeColor(context, session.mode)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tituloContenido(state, session.contentKey), style: context.texto.titleSmall),
                  Text(_fecha(session.endedAt), style: context.texto.bodySmall),
                  if (wearable is Map)
                    Text(
                      '♥ ${wearable['avgHeartRate']} bpm promedio · ${contar((wearable['samples'] as num?) ?? 0, 'lectura', 'lecturas')}',
                      style: context.texto.bodySmall?.copyWith(color: context.paleta.exito),
                    ),
                  if (!session.synced)
                    Text('Pendiente de guardar en el servidor', style: context.texto.bodySmall?.copyWith(color: context.paleta.advertencia)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(clockLabel(Duration(seconds: session.durationSeconds)), style: context.texto.titleSmall),
                Text(
                  session.completed ? 'Completada' : 'Finalizada',
                  style: context.texto.labelSmall?.copyWith(
                    color: session.completed ? context.paleta.exito : context.paleta.textoSecundario,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

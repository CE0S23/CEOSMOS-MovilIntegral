import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../data/catalog.dart';
import 'theme.dart';
import 'widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.state,
    required this.onFavorites,
    required this.onLogout,
  });
  final AppState state;
  final VoidCallback onFavorites, onLogout;
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
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.username,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      user.email,
                      style: const TextStyle(color: Cosmos.muted),
                    ),
                    const SizedBox(height: 8),
                    const Tag('Cuenta local', color: Cosmos.mint),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('A tu ritmo', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text(
                'Duración predeterminada de tus sesiones',
                style: TextStyle(color: Cosmos.muted),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [5, 15, 25, 45]
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
                leading: const Icon(
                  Icons.favorite_outline,
                  color: Cosmos.lavender,
                ),
                title: const Text('Mis favoritos'),
                subtitle: Text(
                  '${workspace.favorites.length} experiencias guardadas',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: onFavorites,
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: Text(
                'Tu historial',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Text(
              '${workspace.history.length} sesiones',
              style: const TextStyle(color: Cosmos.muted, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (workspace.history.isEmpty)
          const EmptyState(
            icon: Icons.history_rounded,
            title: 'Tu primera sesión te espera',
            message:
                'Cuando termines una sesión, encontrarás aquí tu tiempo y tu ambiente.',
          ),
        ...workspace.history.map((session) {
          final item = catalog.firstWhere((m) => m.id == session.mediaId);
          final time = session.endedAt;
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
                        Text(
                          item.title,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${time.day}/${time.month}/${time.year} · ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            color: Cosmos.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        clockLabel(Duration(seconds: session.durationSeconds)),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        session.completed ? 'Completada' : 'Finalizada',
                        style: TextStyle(
                          color: session.completed ? Cosmos.mint : Cosmos.muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 24),
        const Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Acerca de esta entrega',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 10),
              Text(
                'CEOSMOS Móvil Integral · Primer parcial\nInterfaces y modelos unificados en Flutter.',
                style: TextStyle(color: Cosmos.muted),
              ),
              SizedBox(height: 12),
              Text(
                'Los datos permanecen en memoria mientras la app está abierta. Al reiniciar se eliminan cuentas, favoritos, historial y vinculaciones. La API, JWT, passkeys y hardware reales están pendientes de integración.',
                style: TextStyle(color: Cosmos.muted, fontSize: 12),
              ),
            ],
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
                      ? 'Tu sesión de enfoque terminará y se guardará en el historial local.'
                      : 'Podrás volver a entrar mientras no reinicies la app.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Cerrar sesión'),
                  ),
                ],
              ),
            );
            if (logout == true) onLogout();
          },
          icon: const Icon(Icons.logout, size: 18),
          label: const Text('Cerrar sesión'),
        ),
      ],
    );
  }
}

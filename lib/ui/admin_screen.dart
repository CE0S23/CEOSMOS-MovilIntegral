import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../data/api_client.dart';
import 'theme.dart';
import 'widgets.dart';

/// Panel de administración. Solo se muestra a usuarios ADMIN y además cada
/// petición la vuelve a autorizar el servidor (RolesGuard de la API).
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key, required this.state});
  final AppState state;
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  late Future<List<Map<String, dynamic>>> _usuarios;
  late Future<Map<String, dynamic>> _bitacora;
  final Set<String> _ocupados = {};

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() {
    _usuarios = widget.state.data.adminUsers();
    _bitacora = widget.state.data.adminAuditLog();
  }

  Future<void> _accion(String id, Future<void> Function() hacer, String ok) async {
    setState(() => _ocupados.add(id));
    try {
      await hacer();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok)));
      setState(_cargar);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _ocupados.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Protección de ruta en el cliente (además de la del servidor).
    if (!(widget.state.user?.isAdmin ?? false)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Administración')),
        body: const Center(child: Text('No tienes permiso para ver esta sección.')),
      );
    }
    final yo = widget.state.user!.id;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administración'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: () => setState(_cargar),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Usuarios', style: context.texto.headlineSmall),
          const SizedBox(height: 12),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _usuarios,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
              }
              if (snap.hasError) {
                return Aviso('${snap.error}');
              }
              final usuarios = snap.data!;
              if (usuarios.isEmpty) return const Text('No hay usuarios.');
              return Column(
                children: [
                  for (final u in usuarios)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Panel(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${u['username']}', style: context.texto.titleSmall),
                            Text('${u['email']}', style: context.texto.bodySmall),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                Tag('${u['role']}', color: u['role'] == 'ADMIN' ? context.paleta.marca : context.paleta.enlace),
                                Tag(u['active'] == true ? 'Activo' : 'Desactivado',
                                    color: u['active'] == true ? context.paleta.exito : context.paleta.textoSecundario),
                                if (u['emailVerified'] != true) Tag('Sin verificar', color: context.paleta.textoSecundario),
                              ],
                            ),
                            if (u['id'] != yo) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: [
                                  OutlinedButton(
                                    onPressed: _ocupados.contains(u['id'])
                                        ? null
                                        : () => _accion(
                                            u['id'] as String,
                                            () => widget.state.data.adminSetActive(u['id'] as String, u['active'] != true),
                                            u['active'] == true ? 'Usuario desactivado.' : 'Usuario activado.',
                                          ),
                                    child: Text(u['active'] == true ? 'Desactivar' : 'Activar'),
                                  ),
                                  OutlinedButton(
                                    onPressed: _ocupados.contains(u['id'])
                                        ? null
                                        : () => _accion(
                                            u['id'] as String,
                                            () => widget.state.data.adminSetRole(
                                              u['id'] as String,
                                              u['role'] == 'ADMIN' ? 'USER' : 'ADMIN',
                                            ),
                                            'Rol actualizado.',
                                          ),
                                    child: Text(u['role'] == 'ADMIN' ? 'Hacer USER' : 'Hacer ADMIN'),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Text('Bitácora de auditoría', style: context.texto.headlineSmall),
          const SizedBox(height: 12),
          FutureBuilder<Map<String, dynamic>>(
            future: _bitacora,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const LinearProgressIndicator();
              }
              if (snap.hasError) {
                return Aviso('${snap.error}');
              }
              final items = (snap.data!['items'] as List? ?? const []).cast<Map>();
              if (items.isEmpty) return const Text('Sin eventos registrados.');
              return Column(
                children: [
                  for (final e in items)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      leading: Icon(Icons.receipt_long_outlined, color: context.paleta.enlace),
                      title: Text('${e['action']} · ${(e['user'] as Map?)?['email'] ?? e['userId'] ?? 'sistema'}'),
                      subtitle: Text(
                        '${DateTime.tryParse('${e['timestamp']}')?.toLocal() ?? ''} · IP ${e['ipAddress'] ?? '-'}',
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

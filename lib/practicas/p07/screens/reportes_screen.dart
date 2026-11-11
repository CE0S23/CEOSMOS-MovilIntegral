import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/dispositivo.dart';
import '../models/reporte.dart';
import '../services/auth_service.dart';
import '../services/reporte_service.dart';
import '../widgets/chip_estado.dart';
import 'chat_screen.dart';
import 'reporte_form_screen.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key, this.asignadoA});
  final String? asignadoA;

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  final _service = ReporteService();
  final _buscar = TextEditingController();
  List<Reporte> _listaUsuario = [];
  String? _mensajeBusqueda;
  String _filtro = 'Todos';

  Dispositivo get _actual => context.read<AuthService>().actual!;
  bool get _usuario => _actual.rol.startsWith('usuario');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refrescarUsuario());
  }

  @override
  void dispose() {
    _buscar.dispose();
    super.dispose();
  }

  Future<void> _refrescarUsuario() async {
    if (!mounted || !_usuario) return;
    try {
      final lista = await _service.consultarListaUsuario(_actual.uid);
      if (mounted) setState(() => _listaUsuario = lista);
    } catch (e) {
      _error('No se pudieron cargar los tickets: $e');
    }
  }

  Future<void> _consultar() async {
    if (_buscar.text.trim().isEmpty) return;
    try {
      final reporte = await _service.consultarId(_buscar.text);
      if (!mounted) return;
      if (reporte == null) {
        setState(() => _mensajeBusqueda = 'Reporte no encontrado');
      } else {
        setState(() => _mensajeBusqueda = null);
        _abrirChat(reporte);
      }
    } catch (e) {
      _error('No se pudo consultar: $e');
    }
  }

  void _error(String texto) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(texto)));
    }
  }

  Future<void> _abrirChat(Reporte reporte) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => ChatScreen(reporte: reporte)),
    );
    if (mounted) await _refrescarUsuario();
  }

  Future<void> _nuevo() async {
    final resultado = await Navigator.push<({String id, bool pendiente})>(
      context,
      MaterialPageRoute(builder: (_) => ReporteFormScreen(creador: _actual)),
    );
    if (!mounted || resultado == null) return;
    if (resultado.pendiente) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ticket pendiente de sincronizar')),
      );
    }
    await _refrescarUsuario();
    final reporte = _listaUsuario.where((r) => r.id == resultado.id).firstOrNull;
    if (reporte != null) {
      _abrirChat(reporte);
    } else {
      _error(
        'Ticket pendiente de sincronizar. Actualiza la lista para abrirlo.',
      );
    }
  }

  Widget _tarjeta(Reporte reporte) => Card(
    child: ListTile(
      title: Text(reporte.titulo),
      subtitle: Text(
        '${reporte.id} · Turno ${reporte.turno} · ${reporte.prioridad}'
        '${_usuario ? '' : ' · ${reporte.usuarioNombre}'}',
      ),
      trailing: ChipEstado(reporte.estado, pendiente: reporte.pendiente),
      onTap: () => _abrirChat(reporte),
    ),
  );

  Widget _lista(List<Reporte> reportes) {
    final filtrados = _actual.rol == 'agente' && _filtro != 'Todos'
        ? reportes
              .where(
                (r) =>
                    r.estado ==
                    switch (_filtro) {
                      'Abiertos' => 'Abierto',
                      'Pendientes' => 'Pendiente',
                      _ => 'Resuelto',
                    },
              )
              .toList()
        : reportes;
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        if (filtrados.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('Sin tickets')),
          ),
        ...filtrados.map(_tarjeta),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _buscar,
                    decoration: const InputDecoration(
                      labelText: 'Consultar por ID',
                      hintText: 'REP001',
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Consultar',
                  onPressed: _consultar,
                  icon: const Icon(Icons.search),
                ),
                if (_usuario)
                  IconButton(
                    tooltip: 'Actualizar',
                    onPressed: _refrescarUsuario,
                    icon: const Icon(Icons.refresh),
                  ),
              ],
            ),
            if (_mensajeBusqueda != null) Text(_mensajeBusqueda!),
            if (_usuario)
              FilledButton.icon(
                onPressed: _nuevo,
                icon: const Icon(Icons.add),
                label: const Text('Nuevo ticket'),
              ),
            if (_actual.rol == 'agente')
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final filtro in const [
                      'Todos',
                      'Abiertos',
                      'Pendientes',
                      'Resueltos',
                    ])
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(filtro),
                          selected: _filtro == filtro,
                          onSelected: (_) => setState(() => _filtro = filtro),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
      Expanded(
        child: _usuario
            ? _lista(_listaUsuario)
            : StreamBuilder<List<Reporte>>(
                stream: _service.escuchar(
                  asignadoA: _actual.rol == 'agente'
                      ? 'agente'
                      : widget.asignadoA,
                ),
                builder: (context, snapshot) => snapshot.hasError
                    ? Center(child: Text('Error: ${snapshot.error}'))
                    : _lista(snapshot.data ?? []),
              ),
      ),
    ],
  );
}

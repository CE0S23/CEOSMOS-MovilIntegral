import 'package:flutter/material.dart';

import 'app_database.dart';
import 'usuario.dart';
import 'usuario_dao.dart';
import '../../../ui/widgets.dart' show Aviso;

/// [CEOSMOS] Práctica 4, caso 4: el correo es obligatorio y con formato válido.
String? validarCorreoUsuario(String? valor) {
  final correo = valor?.trim() ?? '';
  if (correo.isEmpty) return 'Ingresa el correo.';
  if (correo.length > 120 ||
      !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$').hasMatch(correo)) {
    return 'Ingresa un correo válido.';
  }
  return null;
}

/// Edad entera entre 1 y 120 (extraída del formulario para probarla sin la UI, P13-14).
String? validarEdadUsuario(String? valor) {
  final edad = int.tryParse(valor?.trim() ?? '');
  if (edad == null || edad < 1 || edad > 120) {
    return 'Ingresa una edad entera entre 1 y 120.';
  }
  return null;
}

/// Campo de texto obligatorio (nombre, profesión).
String? Function(String?) validarObligatorio(String mensaje) =>
    (valor) => valor == null || valor.trim().isEmpty ? mensaje : null;

class UsuariosPage extends StatefulWidget {
  const UsuariosPage({super.key, required this.baseDeDatos});

  final Future<AppDatabase> baseDeDatos;

  @override
  State<UsuariosPage> createState() => _UsuariosPageState();
}

class _UsuariosPageState extends State<UsuariosPage> {
  final _formulario = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _edad = TextEditingController();
  final _profesion = TextEditingController();
  final _correo = TextEditingController(); // [CEOSMOS] Práctica 4, caso 4
  UsuarioDao? _dao;
  int? _idSeleccionado;
  List<Usuario> _usuarios = [];
  bool _listaVisible = false;
  bool _ocupado = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _abrirBaseDeDatos();
  }

  Future<void> _abrirBaseDeDatos() async {
    try {
      final base = await widget.baseDeDatos;
      if (!mounted) return;
      setState(() => _dao = base.usuarioDao);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No fue posible abrir la base de datos.');
      }
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  void dispose() {
    _nombre.dispose();
    _edad.dispose();
    _profesion.dispose();
    _correo.dispose();
    super.dispose();
  }

  void _limpiarFormulario() {
    _formulario.currentState?.reset();
    _nombre.clear();
    _edad.clear();
    _profesion.clear();
    _correo.clear();
    setState(() => _idSeleccionado = null);
  }

  Future<void> _ejecutar(Future<void> Function() operacion) async {
    if (_ocupado || _dao == null) return;
    setState(() {
      _ocupado = true;
      _error = null;
    });
    try {
      await operacion();
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No fue posible completar la operación.');
      }
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _consultarUsuarios() async {
    final usuarios = await _dao!.obtenerTodos();
    if (!mounted) return;
    setState(() {
      _usuarios = usuarios;
      _listaVisible = true;
    });
  }

  Future<void> _guardar() async {
    if (!_formulario.currentState!.validate()) return;
    final usuario = Usuario(
      id: _idSeleccionado,
      nombre: _nombre.text.trim(),
      edad: int.parse(_edad.text.trim()),
      profesion: _profesion.text.trim(),
      correo: _correo.text.trim().toLowerCase(),
    );
    await _ejecutar(() async {
      if (usuario.id == null) {
        await _dao!.insertar(usuario);
      } else {
        await _dao!.actualizar(usuario);
      }
      if (!mounted) return;
      _limpiarFormulario();
      if (_listaVisible) await _consultarUsuarios();
    });
  }

  void _seleccionar(Usuario usuario) {
    _formulario.currentState?.reset();
    _nombre.text = usuario.nombre;
    _edad.text = usuario.edad.toString();
    _profesion.text = usuario.profesion;
    _correo.text = usuario.correo ?? '';
    setState(() => _idSeleccionado = usuario.id);
  }

  Future<void> _eliminar(Usuario usuario) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar usuario'),
        content: Text('¿Deseas eliminar a ${usuario.nombre}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ELIMINAR'),
          ),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;
    await _ejecutar(() async {
      await _dao!.eliminar(usuario);
      if (!mounted) return;
      if (_idSeleccionado == usuario.id) _limpiarFormulario();
      if (_listaVisible) await _consultarUsuarios();
    });
  }

  @override
  Widget build(BuildContext context) {
    final habilitado = !_ocupado && _dao != null;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Usuarios', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        Form(
          key: _formulario,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nombre,
                enabled: habilitado,
                decoration: const InputDecoration(labelText: 'Nombre'),
                textCapitalization: TextCapitalization.words,
                validator: validarObligatorio('Ingresa el nombre.'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _edad,
                enabled: habilitado,
                decoration: const InputDecoration(labelText: 'Edad'),
                keyboardType: TextInputType.number,
                validator: validarEdadUsuario,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _profesion,
                enabled: habilitado,
                decoration: const InputDecoration(labelText: 'Profesión'),
                textCapitalization: TextCapitalization.sentences,
                validator: validarObligatorio('Ingresa la profesión.'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _correo,
                enabled: habilitado,
                decoration: const InputDecoration(labelText: 'Correo'),
                keyboardType: TextInputType.emailAddress,
                validator: validarCorreoUsuario,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: habilitado ? _guardar : null,
                child: Text(
                  _idSeleccionado == null ? 'REGISTRAR' : 'ACTUALIZAR',
                ),
              ),
              if (_idSeleccionado != null)
                TextButton(
                  onPressed: habilitado ? _limpiarFormulario : null,
                  child: const Text('CANCELAR EDICIÓN'),
                ),
              OutlinedButton(
                onPressed: habilitado
                    ? () => _ejecutar(_consultarUsuarios)
                    : null,
                child: const Text('VER usuarios'),
              ),
            ],
          ),
        ),
        if (_ocupado)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (_error != null)
          Aviso(_error!), // [CEOSMOS] ícono + texto
        if (_listaVisible) ...[
          const Divider(height: 32),
          if (_usuarios.isEmpty) const Text('No hay usuarios registrados.'),
          for (final usuario in _usuarios)
            Card(
              child: ListTile(
                title: Text(usuario.nombre),
                subtitle: Text(
                  '${usuario.edad} años · ${usuario.profesion}'
                  '${(usuario.correo ?? '').isEmpty ? '' : '\n${usuario.correo}'}',
                ),
                onTap: habilitado ? () => _seleccionar(usuario) : null,
                trailing: IconButton(
                  tooltip: 'Eliminar usuario',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: habilitado ? () => _eliminar(usuario) : null,
                ),
              ),
            ),
        ],
      ],
    );
  }
}

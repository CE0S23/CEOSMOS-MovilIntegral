import '../atras_ceosmos.dart'; // [CEOSMOS]
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'reporte_validation.dart';
import '../../core/theme/theme.dart';

void main() => runApp(const ReportesApp());

class ReportesApp extends StatelessWidget {
  const ReportesApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
      onNavigationNotification: atrasManejadoPorCeosmos, // [CEOSMOS] Atrás vuelve a «Prácticas»
    title: 'Reportes compartidos',
    debugShowCheckedModeBanner: false,
    // [CEOSMOS] Tema compartido del sistema de diseño (claro/oscuro).
    theme: CeosmosTema.claro,
    darkTheme: CeosmosTema.oscuro,
    themeMode: ThemeMode.system,
    home: const ReportesPage(),
  );
}

class ReportesPage extends StatefulWidget {
  const ReportesPage({super.key});

  @override
  State<ReportesPage> createState() => _ReportesPageState();
}

class _ReportesPageState extends State<ReportesPage> {
  static const _channel = MethodChannel('reportes/firestore');
  final _id = TextEditingController(text: 'REP001');
  final _equipo = TextEditingController(text: 'Bomba 1');
  final _descripcion = TextEditingController(text: 'Fuga visible');
  String _prioridad = 'Media';
  String? _uid;
  String _estado = 'Conectando con Firebase…';
  Map<String, String>? _reporte;
  bool _ocupado = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _iniciar();
  }

  @override
  void dispose() {
    _id.dispose();
    _equipo.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  Future<void> _iniciar() async {
    try {
      final uid = await _channel.invokeMethod<String>('initialize');
      if (!mounted) return;
      setState(() {
        _uid = uid;
        _estado = 'Conectado. Listo para probar Firestore.';
      });
    } on PlatformException catch (e) {
      if (mounted) {
        setState(() {
          _error = true;
          _estado = e.message ?? e.code;
        });
      }
    }
  }

  Future<dynamic> _ejecutar(String accion, Map<String, String> datos) async {
    setState(() {
      _ocupado = true;
      _error = false;
      _estado = '$accion: esperando confirmación del servidor…';
    });
    try {
      return await _channel
          .invokeMethod<dynamic>(accion, datos)
          .timeout(const Duration(seconds: 15));
    } on TimeoutException {
      if (mounted) {
        setState(() {
          _error = true;
          _estado =
              'Sin confirmación tras 15 segundos. Reconecta y consulta el ID antes de repetir la escritura.';
        });
      }
    } on PlatformException catch (e) {
      if (mounted) {
        setState(() {
          _error = true;
          _estado = e.message ?? e.code;
        });
      }
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
    return null;
  }

  Map<String, String> get _datos => {
    'id': _id.text.trim(),
    'equipo': _equipo.text.trim(),
    'descripcion': _descripcion.text.trim(),
    'prioridad': _prioridad,
  };

  void _validacion(String mensaje) => setState(() {
    _error = true;
    _estado = mensaje;
  });

  Future<void> _crear() async {
    final d = _datos;
    final error = validarReporte(
      id: d['id']!,
      equipo: d['equipo']!,
      descripcion: d['descripcion']!,
      prioridad: d['prioridad']!,
    );
    if (error != null) {
      _validacion(error);
      return;
    }
    final respuesta = await _ejecutar('create', d);
    if (respuesta is String && mounted) {
      setState(() {
        _reporte = null;
        _estado = respuesta;
      });
    }
  }

  Future<void> _consultar() async {
    final error = validarId(_id.text);
    if (error != null) {
      _validacion(error);
      return;
    }
    final respuesta = await _ejecutar('read', {'id': _id.text.trim()});
    if (!mounted) return;
    if (respuesta == null) {
      if (!_error) {
        setState(() {
          _reporte = null;
          _estado = 'El reporte ${_id.text.trim()} no existe.';
        });
      }
    } else if (respuesta is Map) {
      final reporte = respuesta.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );
      setState(() {
        _reporte = reporte;
        _equipo.text = reporte['equipo'] ?? '';
        _descripcion.text = reporte['descripcion'] ?? '';
        _prioridad = reporte['prioridad'] ?? 'Media';
        _estado = 'Consulta confirmada desde el servidor.';
      });
    }
  }

  Future<void> _actualizar() async {
    final error = validarId(_id.text);
    if (error != null) {
      _validacion(error);
      return;
    }
    final respuesta = await _ejecutar('update', {
      'id': _id.text.trim(),
      'prioridad': _prioridad,
    });
    if (respuesta is String && mounted) {
      setState(() {
        _reporte = null;
        _estado = respuesta;
      });
    }
  }

  Future<void> _eliminar() async {
    final error = validarId(_id.text);
    if (error != null) {
      _validacion(error);
      return;
    }
    final respuesta = await _ejecutar('delete', {'id': _id.text.trim()});
    if (respuesta is String && mounted) {
      setState(() {
        _reporte = null;
        _estado = respuesta;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final puedeOperar = _uid != null && !_ocupado;
    return Scaffold(
      appBar: AppBar(title: const Text('Reportes compartidos')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Pruebas de integridad y persistencia',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Flutter + Kotlin · Proyecto reportes-movil-20261019',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sesión de prueba',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    SelectableText('UID: ${_uid ?? 'pendiente'}'),
                    const SizedBox(height: 8),
                    const Text(
                      'Usa este UID como ownerUid al crear el documento manual en Firebase Console.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _id,
              decoration: const InputDecoration(
                labelText: 'ID',
                hintText: 'REP001',
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _equipo,
              decoration: const InputDecoration(
                labelText: 'Equipo',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descripcion,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Descripción',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey(_prioridad),
              initialValue: _prioridad,
              decoration: const InputDecoration(
                labelText: 'Prioridad',
              ),
              items: const [
                'Baja',
                'Media',
                'Alta',
              ].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
              onChanged: puedeOperar
                  ? (p) => setState(() => _prioridad = p ?? 'Media')
                  : null,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: puedeOperar ? _crear : null,
              icon: const Icon(Icons.add),
              label: const Text('Registrar reporte'),
            ),
            OutlinedButton.icon(
              onPressed: puedeOperar ? _consultar : null,
              icon: const Icon(Icons.search),
              label: const Text('Consultar desde servidor'),
            ),
            OutlinedButton.icon(
              onPressed: puedeOperar ? _actualizar : null,
              icon: const Icon(Icons.edit),
              label: const Text('Actualizar prioridad'),
            ),
            TextButton.icon(
              onPressed: puedeOperar ? _eliminar : null,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Eliminar reporte'),
            ),
            const SizedBox(height: 12),
            Card(
              color: _error
                  ? Theme.of(context).colorScheme.errorContainer
                  : Theme.of(context).colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_estado, key: const Key('estado')),
              ),
            ),
            if (_reporte != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Documento consultado',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      for (final entrada in _reporte!.entries)
                        Text('${entrada.key}: ${entrada.value}'),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

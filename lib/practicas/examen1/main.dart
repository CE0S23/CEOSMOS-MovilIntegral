import '../atras_ceosmos.dart'; // [CEOSMOS]
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const IncidenciasApp());
}

/// Modelo de datos de una incidencia.
class Incidencia {
  final String id;
  final String equipo;
  final String descripcion;
  final String fecha;

  Incidencia({
    required this.id,
    required this.equipo,
    required this.descripcion,
    required this.fecha,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'equipo': equipo,
    'descripcion': descripcion,
    'fecha': fecha,
  };

  factory Incidencia.fromJson(Map<String, dynamic> json) => Incidencia(
    id: json['id'] as String,
    equipo: json['equipo'] as String,
    descripcion: json['descripcion'] as String,
    fecha: json['fecha'] as String,
  );
}

class IncidenciasApp extends StatelessWidget {
  const IncidenciasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onNavigationNotification: atrasManejadoPorCeosmos, // [CEOSMOS] Atrás vuelve a «Prácticas»
      title: 'Incidencias de Soporte',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const PantallaPrincipal(),
    );
  }
}

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  // [CEOSMOS] Clave con prefijo para no compartir el SharedPreferences común de la app.
  static const String _clave = 'examen1.incidencias';

  final _formKey = GlobalKey<FormState>();
  final _equipoCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();

  List<Incidencia> _incidencias = [];
  bool _cargando = true;
  bool _guardando = false;
  String? _errorCarga;

  bool get _ocupado => _cargando || _guardando || _errorCarga != null;

  @override
  void initState() {
    super.initState();
    _cargarIncidencias();
  }

  @override
  void dispose() {
    _equipoCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  /// CONSULTAR: lee la lista guardada en SharedPreferences.
  Future<void> _cargarIncidencias() async {
    setState(() {
      _cargando = true;
      _errorCarga = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final textoJson = prefs.getString(_clave);
      final decoded = textoJson == null
          ? <dynamic>[]
          : jsonDecode(textoJson) as List<dynamic>;
      final lista = decoded
          .map((e) => Incidencia.fromJson(e as Map<String, dynamic>))
          .toList();
      if (!mounted) return;
      setState(() => _incidencias = lista);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorCarga =
            'No se pudieron leer las incidencias. '
            'Los datos guardados no se han modificado.';
      });
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  /// Persiste la lista completa como JSON.
  Future<void> _persistir(List<Incidencia> lista) async {
    final prefs = await SharedPreferences.getInstance();
    final textoJson = jsonEncode(lista.map((i) => i.toJson()).toList());
    final guardado = await prefs.setString(_clave, textoJson);
    if (!guardado) throw StateError('No se pudo guardar en el dispositivo');
  }

  String _fechaActual() {
    final n = DateTime.now();
    String dos(int v) => v.toString().padLeft(2, '0');
    return '${dos(n.day)}/${dos(n.month)}/${n.year} ${dos(n.hour)}:${dos(n.minute)}';
  }

  /// GUARDAR: valida, registra, guarda y limpia los campos.
  Future<void> _guardarIncidencia() async {
    if (_ocupado) return;
    if (!_formKey.currentState!.validate()) return;

    final nueva = Incidencia(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      equipo: _equipoCtrl.text.trim(),
      descripcion: _descripcionCtrl.text.trim(),
      fecha: _fechaActual(),
    );

    setState(() => _guardando = true);
    try {
      final lista = [nueva, ..._incidencias];
      await _persistir(lista);
      if (!mounted) return;
      setState(() => _incidencias = lista);
      _formKey.currentState!.reset();
      _equipoCtrl.clear();
      _descripcionCtrl.clear();
      FocusScope.of(context).unfocus();
      _mostrarMensaje('Incidencia guardada');
    } catch (_) {
      if (mounted) {
        _mostrarMensaje(
          'No se pudo guardar. Tus campos se conservaron; intenta de nuevo.',
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  /// ELIMINAR: quita una incidencia y actualiza el almacenamiento.
  Future<void> _eliminarIncidencia(Incidencia inc) async {
    if (_ocupado) return;
    setState(() => _guardando = true);
    try {
      final lista = _incidencias.where((i) => i.id != inc.id).toList();
      await _persistir(lista);
      if (!mounted) return;
      setState(() => _incidencias = lista);
      _mostrarMensaje('Incidencia eliminada');
    } catch (_) {
      if (mounted) _mostrarMensaje('No se pudo eliminar. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  String? _validarObligatorio(String? valor, String campo) {
    if (valor == null || valor.trim().isEmpty) {
      return 'El campo "$campo" es obligatorio';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Incidencias de Soporte'),
        backgroundColor: tema.colorScheme.inversePrimary,
      ),
      body: SafeArea(
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        enabled: !_ocupado,
                        controller: _equipoCtrl,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Nombre del equipo',
                          prefixIcon: Icon(Icons.computer),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            _validarObligatorio(v, 'Nombre del equipo'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        enabled: !_ocupado,
                        controller: _descripcionCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Descripción de la incidencia',
                          prefixIcon: Icon(Icons.description),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => _validarObligatorio(
                          v,
                          'Descripción de la incidencia',
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _ocupado ? null : _guardarIncidencia,
                          icon: const Icon(Icons.save),
                          label: const Text('Guardar incidencia'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: Divider(height: 1)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Incidencias registradas (${_incidencias.length})',
                    style: tema.textTheme.titleMedium,
                  ),
                ),
              ),
            ),
            if (_cargando)
              const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorCarga != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(_errorCarga!, textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _cargarIncidencias,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar carga'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_incidencias.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('No hay incidencias registradas')),
                ),
              )
            else
              SliverList.builder(
                itemCount: _incidencias.length,
                itemBuilder: (context, index) {
                  final inc = _incidencias[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.build_circle),
                      title: Text(inc.equipo),
                      subtitle: Text('${inc.descripcion}\n${inc.fecha}'),
                      isThreeLine: true,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Eliminar',
                        onPressed: _ocupado
                            ? null
                            : () => _eliminarIncidencia(inc),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

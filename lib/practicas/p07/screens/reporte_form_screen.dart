import 'package:flutter/material.dart';

import '../models/dispositivo.dart';
import '../services/reporte_service.dart';

class ReporteFormScreen extends StatefulWidget {
  const ReporteFormScreen({super.key, required this.creador});
  final Dispositivo creador;

  @override
  State<ReporteFormScreen> createState() => _ReporteFormScreenState();
}

class _ReporteFormScreenState extends State<ReporteFormScreen> {
  final _form = GlobalKey<FormState>();
  final _id = TextEditingController();
  final _titulo = TextEditingController();
  final _equipo = TextEditingController();
  final _descripcion = TextEditingController();
  String _prioridad = 'Media';
  bool _guardando = false;

  @override
  void dispose() {
    _id.dispose();
    _titulo.dispose();
    _equipo.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      final resultado = await ReporteService().crear(
        id: _id.text,
        titulo: _titulo.text,
        equipo: _equipo.text,
        descripcion: _descripcion.text,
        prioridad: _prioridad,
        creador: widget.creador,
      );
      if (!mounted) return;
      if (resultado == ResultadoAlta.repetido) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('ID existente'),
            content: const Text('El ID ya existe, no se sobrescribe'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Aceptar'),
              ),
            ],
          ),
        );
      } else {
        Navigator.pop(context, (
          id: _id.text.trim().toUpperCase(),
          pendiente: resultado == ResultadoAlta.pendiente,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('No se pudo guardar: $e')));
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Nuevo ticket')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _id,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(labelText: 'ID (ej. REP001)'),
                validator: (v) =>
                    v == null ||
                        !RegExp(r'^REP[0-9]+$').hasMatch(v.trim().toUpperCase())
                    ? 'Escribe un ID como REP001'
                    : null,
              ),
              TextFormField(
                controller: _titulo,
                maxLength: 80,
                decoration: const InputDecoration(labelText: 'Título'),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'El título es obligatorio'
                    : null,
              ),
              TextFormField(
                controller: _equipo,
                decoration: const InputDecoration(labelText: 'Equipo'),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'El equipo es obligatorio'
                    : null,
              ),
              TextFormField(
                controller: _descripcion,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Descripción'),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'La descripción es obligatoria'
                    : null,
              ),
              DropdownButtonFormField<String>(
                initialValue: _prioridad,
                decoration: const InputDecoration(labelText: 'Prioridad'),
                items: const ['Baja', 'Media', 'Alta']
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (p) {
                  if (p != null) setState(() => _prioridad = p);
                },
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _guardando ? null : _guardar,
                child: const Text('Guardar'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

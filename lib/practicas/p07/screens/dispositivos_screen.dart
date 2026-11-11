import 'package:flutter/material.dart';

import '../models/dispositivo.dart';
import '../services/dispositivo_service.dart';

class DispositivosScreen extends StatelessWidget {
  const DispositivosScreen({super.key});

  Future<void> _rol(BuildContext context, Dispositivo dispositivo) async {
    final rol = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('Cambiar rol: ${dispositivo.nombre}'),
        children: const ['admin', 'agente', 'usuario1', 'usuario2']
            .map(
              (r) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, r),
                child: Text(r),
              ),
            )
            .toList(),
      ),
    );
    if (rol == null) return;
    try {
      await DispositivoService().cambiarRol(dispositivo.uid, rol);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo cambiar el rol: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<List<Dispositivo>>(
    stream: DispositivoService().escuchar(),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Center(child: Text('Error: ${snapshot.error}'));
      }
      final dispositivos = snapshot.data ?? [];
      return ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Text('Dispositivos', style: Theme.of(context).textTheme.titleLarge),
          ...dispositivos.map(
            (d) => Card(
              child: ListTile(
                title: Text(d.nombre),
                subtitle: Text(
                  '${d.rol} · ${d.enLinea ? "conectado" : "desconectado"}',
                ),
                trailing: TextButton(
                  onPressed: () => _rol(context, d),
                  child: const Text('Cambiar rol'),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

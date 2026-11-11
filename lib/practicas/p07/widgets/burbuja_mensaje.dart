import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/mensaje.dart';
import '../utils/abrir_url.dart';

class BurbujaMensaje extends StatelessWidget {
  const BurbujaMensaje({
    super.key,
    required this.mensaje,
    required this.propio,
  });
  final Mensaje mensaje;
  final bool propio;

  @override
  Widget build(BuildContext context) => Align(
    alignment: propio ? Alignment.centerRight : Alignment.centerLeft,
    child: Card(
      color: mensaje.tipo == 'solicitud'
          ? Theme.of(context).colorScheme.tertiaryContainer
          : null,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${mensaje.emisorNombre} · ${mensaje.emisorRol}',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            Text(mensaje.texto),
            if (mensaje.archivoUrl != null || mensaje.archivoBase64 != null)
              TextButton.icon(
                icon: const Icon(Icons.attach_file),
                label: Text(mensaje.archivoNombre ?? 'Descargar archivo'),
                onPressed: () async {
                  try {
                    final contenido = mensaje.archivoBase64;
                    if (contenido != null) {
                      final nombre = mensaje.archivoNombre ?? 'archivo.bin';
                      await FilePicker.platform.saveFile(
                        fileName: nombre.contains('.') ? nombre : '$nombre.bin',
                        bytes: base64Decode(contenido),
                      );
                    } else {
                      await abrirUrl(mensaje.archivoUrl!);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('No se pudo abrir el archivo: $e'),
                        ),
                      );
                    }
                  }
                },
              ),
            Text(
              mensaje.hora == null
                  ? 'Pendiente'
                  : DateFormat('HH:mm').format(mensaje.hora!),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    ),
  );
}

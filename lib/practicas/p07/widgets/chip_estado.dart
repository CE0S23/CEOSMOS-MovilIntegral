import 'package:flutter/material.dart';

class ChipEstado extends StatelessWidget {
  const ChipEstado(this.estado, {super.key, this.pendiente = false});
  final String estado;
  final bool pendiente;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 4,
    children: [
      Chip(label: Text(estado)),
      if (pendiente)
        const Chip(
          label: Text('Pendiente'),
          avatar: Icon(Icons.sync, size: 16),
        ),
    ],
  );
}

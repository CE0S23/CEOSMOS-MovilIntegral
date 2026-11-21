import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'colores.dart';

/// Patrón decorativo de la paleta: líneas curvas guinda sobre cian.
/// Solo para splash, acceso y encabezado del Inicio; nunca detrás de texto largo.
class CurvasCeosmos extends StatelessWidget {
  const CurvasCeosmos({super.key, this.height, this.child, this.radio = 20});
  final double? height;
  final Widget? child;
  final double radio;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: ClipRRect(
      borderRadius: BorderRadius.circular(radio),
      child: SizedBox(
        height: height,
        child: CustomPaint(
          painter: const _CurvasPainter(),
          child: child ?? const SizedBox.expand(),
        ),
      ),
    ),
  );
}

class _CurvasPainter extends CustomPainter {
  const _CurvasPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = CeosmosColores.cian);
    final linea = Paint()
      ..color = CeosmosColores.guinda
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    // Ondas paralelas que se abren hacia la derecha, como en la paleta.
    const lineas = 9;
    for (var i = 0; i < lineas; i++) {
      final t = i / (lineas - 1);
      linea.strokeWidth = 1.4 + t * 2.2;
      final y0 = size.height * (.12 + t * .9);
      final amp = size.height * (.16 + t * .10) + size.width * .015;
      final path = Path()..moveTo(-10, y0);
      for (var x = 0; x <= 48; x++) {
        final dx = x / 48 * (size.width + 20) - 10;
        final y = y0 + math.sin(x / 48 * math.pi * 2.2 + t * 1.6) * amp;
        path.lineTo(dx, y);
      }
      canvas.drawPath(path, linea);
    }
  }

  @override
  bool shouldRepaint(_CurvasPainter oldDelegate) => false;
}

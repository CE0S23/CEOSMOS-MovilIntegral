import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show TextInputFormatter;
import '../domain/models.dart';
import 'theme.dart';


/// Color de cada intención en su variante legible del tema activo:
/// guinda (enfoque), cian (calma) y ámbar (inspiración).
Color modeColor(BuildContext context, FocusMode mode) {
  final p = context.paleta;
  return switch (mode) {
    FocusMode.focus => p.marca,
    FocusMode.relax => p.enlace,
    FocusMode.inspire =>
      Theme.of(context).brightness == Brightness.dark
          ? p.acento
          : CeosmosColores.advertenciaTexto,
  };
}

IconData modeIcon(FocusMode mode) => switch (mode) {
  FocusMode.focus => Icons.blur_on_rounded,
  FocusMode.relax => Icons.spa_outlined,
  FocusMode.inspire => Icons.auto_awesome_outlined,
};
String clockLabel(Duration duration) =>
    '${duration.inMinutes.toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';

class Brand extends StatelessWidget {
  const Brand({super.key, this.compact = false});
  final bool compact;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: CeosmosColores.cian,
          borderRadius: Radios.bordeS,
        ),
        child: const Icon(
          Icons.all_inclusive,
          color: CeosmosColores.guinda,
          size: 25,
        ),
      ),
      if (!compact) ...[
        const SizedBox(width: Espacio.m),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'CEOSMOS',
              style: context.texto.titleLarge?.copyWith(
                color: context.paleta.marca,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ],
    ],
  );
}

class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Espacio.xl),
    this.color,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color ?? context.paleta.superficie,
      borderRadius: Radios.bordeL,
      border: Border.all(color: context.paleta.borde),
      boxShadow: Theme.of(context).brightness == Brightness.light
          ? Sombra.suave
          : null,
    ),
    child: child,
  );
}

class Tag extends StatelessWidget {
  const Tag(this.label, {super.key, this.color, this.icon});
  final String label;
  final Color? color;
  final IconData? icon;
  @override
  Widget build(BuildContext context) {
    final color = this.color ?? context.paleta.enlace;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Espacio.m, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(Radios.pildora),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: Espacio.xs + 1),
          ],
          Flexible(
            child: Text(
              label,
              style: context.texto.labelSmall?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class PageHeading extends StatelessWidget {
  const PageHeading(this.title, this.subtitle, {super.key});
  final String title, subtitle;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Espacio.xl),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: context.texto.headlineMedium?.copyWith(
            color: context.paleta.marca,
          ),
        ),
        const SizedBox(height: Espacio.s),
        Text(
          subtitle,
          style: context.texto.bodyLarge?.copyWith(
            color: context.paleta.textoSecundario,
          ),
        ),
      ],
    ),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });
  final IconData icon;
  final String title, message;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Panel(
    child: Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Espacio.xl),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: context.paleta.cianSuave,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 34, color: context.paleta.enlace),
            ),
            const SizedBox(height: Espacio.l),
            Text(
              title,
              style: context.texto.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Espacio.s),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.paleta.textoSecundario),
            ),
            if (action != null) ...[
              const SizedBox(height: Espacio.xl),
              action!,
            ],
          ],
        ),
      ),
    ),
  );
}

/// Mensaje de estado con ícono + texto: el color nunca va solo, y el error
/// se distingue del guinda de marca por el ícono y su tono rojo.
enum TipoAviso { error, advertencia, exito, info }

class Aviso extends StatelessWidget {
  const Aviso(this.texto, {super.key, this.tipo = TipoAviso.error, this.style});
  final String texto;
  final TipoAviso tipo;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final (icono, color) = switch (tipo) {
      TipoAviso.error => (Icons.error_outline, p.error),
      TipoAviso.advertencia => (Icons.warning_amber_rounded, p.advertencia),
      TipoAviso.exito => (Icons.check_circle_outline, p.exito),
      TipoAviso.info => (Icons.info_outline, p.info),
    };
    final estilo = (style ?? context.texto.bodyMedium)?.copyWith(
      color: color,
      fontWeight: FontWeight.w500,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icono, size: (estilo?.fontSize ?? 14) + 4, color: color),
        ),
        const SizedBox(width: Espacio.s),
        Flexible(child: Text(texto, style: estilo)),
      ],
    );
  }
}

/// Original vector scenery: bundled, deterministic and available offline.
class CosmosScene extends StatelessWidget {
  const CosmosScene({super.key, this.scene = 0, this.child, this.height});
  final int scene;
  final Widget? child;
  final double? height;
  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: ClipRRect(
      borderRadius: Radios.bordeL,
      child: SizedBox(
        height: height,
        child: CustomPaint(
          painter: _ScenePainter(scene),
          child: child ?? const SizedBox.expand(),
        ),
      ),
    ),
  );
}

class _ScenePainter extends CustomPainter {
  const _ScenePainter(this.scene);
  final int scene;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    // Escenas derivadas de la paleta (guindas profundos y cianes nocturnos),
    // siempre lo bastante oscuras para llevar texto blanco encima.
    const palettes = [
      [Color(0xFF2A0010), CeosmosColores.guindaMedio],
      [Color(0xFF032631), CeosmosColores.cianTexto],
      [Color(0xFF3A0716), Color(0xFFA0425E)],
      [CeosmosColores.tinta, CeosmosColores.guinda],
      [Color(0xFF04303D), Color(0xFF2C8FB0)],
      [Color(0xFF2C0A18), Color(0xFF8E3E5C)],
    ];
    final colors = palettes[scene % palettes.length];
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ).createShader(rect),
    );
    final random = math.Random(42 + scene);
    for (var i = 0; i < 70; i++) {
      canvas.drawCircle(
        Offset(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height * .85,
        ),
        random.nextDouble() * 1.2 + .3,
        Paint()
          ..color = CeosmosColores.blanco.withValues(
            alpha: random.nextDouble() * .5 + .1,
          ),
      );
    }
    final center = Offset(size.width * .72, size.height * .4);
    final radius = math.min(size.width * .18, size.height * .25);
    canvas.drawCircle(
      center,
      radius * 1.9,
      Paint()
        ..shader = RadialGradient(
          colors: [
            colors.last.withValues(alpha: .55),
            colors.last.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius * 1.9)),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(colors.last, CeosmosColores.cianClaro, .5)!,
            colors.first,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    if (scene == 0 || scene == 3) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(-.3);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: radius * 3.4,
          height: radius * .8,
        ),
        Paint()
          ..color = CeosmosColores.cian.withValues(alpha: .75)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      canvas.restore();
    }
    for (var layer = 0; layer < 3; layer++) {
      final path = Path()..moveTo(0, size.height);
      for (var x = 0; x <= 40; x++) {
        final dx = x / 40 * size.width;
        final wave =
            math.sin(x * .16 + layer * 1.7 + scene) * size.height * .11;
        path.lineTo(dx, size.height * (.7 + layer * .11) + wave);
      }
      path.lineTo(size.width, size.height);
      path.close();
      canvas.drawPath(
        path,
        Paint()
          ..color = Color.lerp(
            colors.first,
            CeosmosColores.tinta,
            layer / 3,
          )!.withValues(alpha: .75),
      );
    }
    if (scene == 1) {
      for (var i = 0; i < 14; i++) {
        final x = i * size.width / 13;
        final h = (random.nextDouble() * .16 + .14) * size.height;
        final y = size.height * .9;
        canvas.drawPath(
          Path()
            ..moveTo(x, y - h)
            ..lineTo(x - h * .35, y)
            ..lineTo(x + h * .35, y)
            ..close(),
          Paint()..color = const Color(0xFF021C24),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_ScenePainter oldDelegate) => scene != oldDelegate.scene;
}

class MediaCard extends StatelessWidget {
  const MediaCard({
    super.key,
    required this.item,
    required this.favorite,
    required this.onOpen,
    required this.onFavorite,
  });
  final MediaItem item;
  final bool favorite;
  final VoidCallback onOpen, onFavorite;
  @override
  Widget build(BuildContext context) => Material(
    color: context.paleta.superficie,
    shape: RoundedRectangleBorder(
      borderRadius: Radios.bordeL,
      side: BorderSide(color: context.paleta.borde),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              CosmosScene(
                scene: item.scene,
                height: 154,
                child: const SizedBox(width: double.infinity),
              ),
              Positioned(
                left: Espacio.m,
                bottom: Espacio.m,
                child: Tag(
                  item.kind == MediaKind.audio ? 'Audio' : 'Paisaje',
                  icon: item.kind == MediaKind.audio
                      ? Icons.headphones
                      : Icons.landscape_outlined,
                  color: CeosmosColores.blanco,
                ),
              ),
              Positioned(
                right: 6,
                top: 6,
                child: IconButton.filledTonal(
                  onPressed: onFavorite,
                  tooltip: favorite
                      ? 'Quitar ${item.title} de favoritos'
                      : 'Guardar ${item.title}',
                  icon: Icon(
                    favorite ? Icons.favorite : Icons.favorite_border,
                    size: 19,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: CeosmosColores.tinta.withValues(
                      alpha: .55,
                    ),
                    foregroundColor: favorite
                        ? CeosmosColores.cian
                        : CeosmosColores.blanco,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(Espacio.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.mode.label.toUpperCase(),
                  style: context.texto.labelSmall?.copyWith(
                    letterSpacing: 1.2,
                    color: modeColor(context, item.mode),
                  ),
                ),
                const SizedBox(height: Espacio.s),
                Text(item.title, style: context.texto.titleLarge),
                const SizedBox(height: Espacio.xs),
                Text(item.subtitle, style: context.texto.bodySmall),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

/// Campo de un [FormDialog].
class DialogField {
  const DialogField(
    this.label, {
    this.initial = '',
    this.hint,
    this.validator,
    this.keyboardType,
    this.maxLength,
    this.inputFormatters,
  });
  final String label;
  final List<TextInputFormatter>? inputFormatters;
  final String initial;
  final String? hint;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final int? maxLength;
}

/// Diálogo con formulario que es dueño de sus controladores (se liberan al
/// desmontarse, después de la animación de cierre). Devuelve los valores
/// escritos o null si se cancela.
class FormDialog extends StatefulWidget {
  const FormDialog({
    super.key,
    required this.title,
    required this.fields,
    required this.confirmLabel,
  });
  final String title, confirmLabel;
  final List<DialogField> fields;

  @override
  State<FormDialog> createState() => _FormDialogState();
}

class _FormDialogState extends State<FormDialog> {
  final _form = GlobalKey<FormState>();
  late final List<TextEditingController> _controllers = [
    for (final f in widget.fields) TextEditingController(text: f.initial),
  ];

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: Form(
      key: _form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < widget.fields.length; i++)
            TextFormField(
              controller: _controllers[i],
              autofocus: i == 0,
              keyboardType: widget.fields[i].keyboardType,
              maxLength: widget.fields[i].maxLength,
              inputFormatters: widget.fields[i].inputFormatters,
              validator: widget.fields[i].validator,
              decoration: InputDecoration(
                labelText: widget.fields[i].label,
                hintText: widget.fields[i].hint,
              ),
            ),
        ],
      ),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
      FilledButton(
        onPressed: () {
          if (_form.currentState!.validate()) {
            Navigator.pop(context, [for (final c in _controllers) c.text.trim()]);
          }
        },
        child: Text(widget.confirmLabel),
      ),
    ],
  );
}

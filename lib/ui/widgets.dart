import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../domain/models.dart';
import 'theme.dart';

Color modeColor(FocusMode mode) => switch (mode) {
  FocusMode.focus => Cosmos.lavender,
  FocusMode.relax => Cosmos.mint,
  FocusMode.inspire => Cosmos.peach,
};
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
          color: Cosmos.lavender.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.all_inclusive,
          color: Cosmos.lavender,
          size: 25,
        ),
      ),
      if (!compact) ...[
        const SizedBox(width: 12),
        const Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'CEOSMOS',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.4,
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
    this.padding = const EdgeInsets.all(22),
    this.color = Cosmos.surface,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: Cosmos.border),
    ),
    child: child,
  );
}

class Tag extends StatelessWidget {
  const Tag(this.label, {super.key, this.color = Cosmos.lavender, this.icon});
  final String label;
  final Color color;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
        ],
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

class PageHeading extends StatelessWidget {
  const PageHeading(this.title, this.subtitle, {super.key});
  final String title, subtitle;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 26),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(subtitle, style: const TextStyle(color: Cosmos.muted)),
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
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Column(
          children: [
            Icon(icon, size: 40, color: Cosmos.lavender),
            const SizedBox(height: 18),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Cosmos.muted),
            ),
            if (action != null) ...[const SizedBox(height: 22), action!],
          ],
        ),
      ),
    ),
  );
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
      borderRadius: BorderRadius.circular(18),
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
    final palettes = [
      [const Color(0xFF1B173A), const Color(0xFF524774)],
      [const Color(0xFF102D30), const Color(0xFF4E8673)],
      [const Color(0xFF37253C), const Color(0xFFCD987E)],
      [const Color(0xFF121E43), const Color(0xFF80649E)],
      [const Color(0xFF103344), const Color(0xFF568F9F)],
      [const Color(0xFF222443), const Color(0xFFAD8895)],
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
          ..color = Colors.white.withValues(
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
          colors: [Color.lerp(colors.last, Colors.white, .5)!, colors.first],
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
          ..color = Cosmos.lavender.withValues(alpha: .6)
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
            const Color(0xFF080D1B),
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
          Paint()..color = const Color(0xFF0B2625),
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
    color: Cosmos.surface,
    borderRadius: BorderRadius.circular(20),
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
                left: 12,
                bottom: 12,
                child: Tag(
                  item.kind == MediaKind.audio ? 'Audio' : 'Paisaje',
                  icon: item.kind == MediaKind.audio
                      ? Icons.headphones
                      : Icons.landscape_outlined,
                  color: Colors.white,
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
                    backgroundColor: Cosmos.background.withValues(alpha: .65),
                    foregroundColor: favorite ? Cosmos.lavender : Colors.white,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.mode.label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.5,
                    color: modeColor(item.mode),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  item.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 5),
                Text(
                  item.subtitle,
                  style: const TextStyle(fontSize: 12, color: Cosmos.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

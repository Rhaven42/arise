import 'package:arise/core/theme/arise_colors.dart';
import 'package:arise/core/theme/arise_spacing.dart';
import 'package:flutter/material.dart';

/// Matière du cadre.
enum FrameMaterial { stone, wood }

/// Panneau orné : pierre sombre en dégradé, liseré de bronze, reflet doré
/// en haut et équerres d'or aux quatre coins.
class StoneFrame extends StatelessWidget {
  const StoneFrame({
    required this.child,
    super.key,
    this.material = FrameMaterial.stone,
    this.padding = const EdgeInsets.all(AriseSpacing.md),
  });

  final Widget child;
  final FrameMaterial material;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final (top, bottom) = switch (material) {
      FrameMaterial.stone => (AriseColors.panelTop, AriseColors.panelBottom),
      FrameMaterial.wood => (AriseColors.wood, AriseColors.stoneDark),
    };
    return CustomPaint(
      foregroundPainter: const CornerBracketsPainter(color: AriseColors.gold),
      child: Padding(
        // Place pour les équerres qui dépassent du panneau.
        padding: const EdgeInsets.all(3),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AriseSpacing.radius),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [top, bottom],
            ),
            border: Border.all(color: AriseColors.bronzeEdge),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 12,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: DecoratedBox(
            // Reflet doré le long du bord supérieur.
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AriseSpacing.radius),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: const Alignment(0, -0.85),
                colors: [
                  AriseColors.goldBright.withValues(alpha: 0.12),
                  Colors.transparent,
                ],
              ),
            ),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

/// Équerres aux quatre coins d'un panneau.
class CornerBracketsPainter extends CustomPainter {
  const CornerBracketsPainter({
    required this.color,
    this.length = 16,
    this.glow = false,
  });

  final Color color;
  final double length;

  /// Lueur autour des équerres (fenêtres du Système).
  final bool glow;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;
    if (glow) {
      paint.maskFilter = const MaskFilter.blur(BlurStyle.solid, 3);
    }
    final w = size.width;
    final h = size.height;
    final l = length;
    final path = Path()
      ..moveTo(1, l)
      ..lineTo(1, 1)
      ..lineTo(l, 1)
      ..moveTo(w - l, 1)
      ..lineTo(w - 1, 1)
      ..lineTo(w - 1, l)
      ..moveTo(1, h - l)
      ..lineTo(1, h - 1)
      ..lineTo(l, h - 1)
      ..moveTo(w - l, h - 1)
      ..lineTo(w - 1, h - 1)
      ..lineTo(w - 1, h - l);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CornerBracketsPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.length != length ||
      oldDelegate.glow != glow;
}

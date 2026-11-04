import 'package:arise/core/theme/arise_colors.dart';
import 'package:arise/core/theme/arise_spacing.dart';
import 'package:flutter/material.dart';

/// Matière du cadre.
enum FrameMaterial { stone, wood }

/// Cadre de pierre ou de bois, avec liseré doré et rivets aux coins.
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
    final (light, dark, edge) = switch (material) {
      FrameMaterial.stone => (
        AriseColors.stoneLight,
        AriseColors.stoneDark,
        AriseColors.abyss,
      ),
      FrameMaterial.wood => (
        AriseColors.woodLight,
        AriseColors.wood,
        AriseColors.onGold,
      ),
    };

    return CustomPaint(
      foregroundPainter: const _RivetPainter(),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [light, dark],
          ),
          border: Border.all(color: edge, width: AriseSpacing.frameBorder),
          borderRadius: BorderRadius.circular(AriseSpacing.radius),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Container(
          margin: const EdgeInsets.all(AriseSpacing.xs),
          padding: padding,
          decoration: BoxDecoration(
            color: AriseColors.stone.withValues(alpha: 0.85),
            border: Border.all(
              color: AriseColors.gold.withValues(alpha: 0.6),
            ),
            borderRadius: BorderRadius.circular(AriseSpacing.radius / 2),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Dessine quatre rivets dorés aux coins du cadre.
class _RivetPainter extends CustomPainter {
  const _RivetPainter();

  static const _radius = 3.5;
  static const _inset = 7.0;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = AriseColors.gold;
    final shade = Paint()..color = AriseColors.onGold;
    final centers = [
      const Offset(_inset, _inset),
      Offset(size.width - _inset, _inset),
      Offset(_inset, size.height - _inset),
      Offset(size.width - _inset, size.height - _inset),
    ];
    for (final center in centers) {
      canvas
        ..drawCircle(center + const Offset(0.6, 0.8), _radius, shade)
        ..drawCircle(center, _radius, fill);
    }
  }

  @override
  bool shouldRepaint(covariant _RivetPainter oldDelegate) => false;
}

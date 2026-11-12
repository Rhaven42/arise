import 'dart:math' as math;

import 'package:arise/core/theme/arise_colors.dart';
import 'package:flutter/material.dart';

/// Fond des pages : pierre sombre, halo de mana en haut, braise en bas,
/// cercle de runes discret et vignettage.
class AriseBackdrop extends StatelessWidget {
  const AriseBackdrop({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(painter: const _BackdropPainter(), child: child),
    );
  }
}

class _BackdropPainter extends CustomPainter {
  const _BackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    // Pierre, puis halo de mana en haut et braise en bas.
    canvas
      ..drawRect(
        rect,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(-0.6, -0.4),
            radius: 1.4,
            colors: [AriseColors.backdropTop, AriseColors.backdropBottom],
          ).createShader(rect),
      )
      ..drawRect(
        rect,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(0, -0.75),
            radius: 0.9,
            colors: [
              AriseColors.mana.withValues(alpha: 0.10),
              AriseColors.mana.withValues(alpha: 0),
            ],
          ).createShader(rect),
      )
      ..drawRect(
        rect,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(0, 1.25),
            radius: 1.1,
            colors: [
              AriseColors.ember.withValues(alpha: 0.16),
              AriseColors.ember.withValues(alpha: 0),
            ],
          ).createShader(rect),
      );
    // Cercle de runes.
    final center = Offset(size.width / 2, size.height * 0.55);
    final radius = math.min(size.width, size.height) * 0.55;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..color = AriseColors.gold.withValues(alpha: 0.06);
    canvas
      ..drawCircle(center, radius, ring..strokeWidth = 1)
      ..drawCircle(center, radius + 18, ring..strokeWidth = 1);
    final tick = Paint()
      ..color = AriseColors.gold.withValues(alpha: 0.07)
      ..strokeWidth = 2;
    for (var i = 0; i < 24; i++) {
      final a = i * math.pi / 12;
      final dir = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(
        center + dir * (radius + 4),
        center + dir * (radius + 14),
        tick,
      );
    }
    // Vignettage.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          radius: 0.95,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.55)],
          stops: const [0.6, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _BackdropPainter oldDelegate) => false;
}

/// Transition de page qui peint le fond sous chaque page (les pages sont
/// transparentes) avant l'animation habituelle.
class AriseBackdropTransitionsBuilder extends PageTransitionsBuilder {
  const AriseBackdropTransitionsBuilder();

  static const _inner = ZoomPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => _inner.buildTransitions(
    route,
    context,
    animation,
    secondaryAnimation,
    AriseBackdrop(child: child),
  );
}

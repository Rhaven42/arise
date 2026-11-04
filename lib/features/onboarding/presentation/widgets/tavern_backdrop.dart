import 'dart:math' as math;

import 'package:arise/core/theme/arise_colors.dart';
import 'package:flutter/material.dart';

/// Décor de taverne dessiné en code : murs de planches, poutres, fenêtre
/// au clair de lune, lanternes et lueur de l'âtre.
///
/// La lueur apparaît en fondu une seule fois (pas d'animation continue,
/// pour la batterie et l'accessibilité).
class TavernBackdrop extends StatelessWidget {
  const TavernBackdrop({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: reduceMotion ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 1400),
      curve: Curves.easeOut,
      builder: (context, glow, child) => CustomPaint(
        painter: _TavernPainter(glow: glow),
        child: child,
      ),
      child: child,
    );
  }
}

class _TavernPainter extends CustomPainter {
  const _TavernPainter({required this.glow});

  /// Intensité de la lueur, de 0 à 1.
  final double glow;

  static const _plankHeight = 38.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Mur de planches, plus sombre en haut.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AriseColors.abyss, AriseColors.wood, AriseColors.abyss],
          stops: [0, 0.65, 1],
        ).createShader(rect),
    );
    final seam = Paint()
      ..color = AriseColors.abyss.withValues(alpha: 0.55)
      ..strokeWidth = 1.5;
    for (var y = _plankHeight; y < size.height; y += _plankHeight) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), seam);
    }

    _paintWindow(canvas, size);
    _paintBeams(canvas, size);
    _paintLanterns(canvas, size);
    _paintHearthGlow(canvas, size);
  }

  void _paintBeams(Canvas canvas, Size size) {
    final beam = Paint()..color = AriseColors.onGold;
    final highlight = Paint()
      ..color = AriseColors.woodLight.withValues(alpha: 0.5);
    final beamTop = Rect.fromLTWH(0, size.height * 0.08, size.width, 22);
    canvas
      ..drawRect(beamTop, beam)
      ..drawRect(
        Rect.fromLTWH(0, beamTop.top, size.width, 3),
        highlight,
      );
    for (final x in [size.width * 0.08, size.width * 0.92 - 20]) {
      final post = Rect.fromLTWH(x, beamTop.bottom, 20, size.height);
      canvas
        ..drawRect(post, beam)
        ..drawRect(Rect.fromLTWH(x, post.top, 3, post.height), highlight);
    }
  }

  void _paintWindow(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.24);
    final window = Rect.fromCenter(
      center: center,
      width: math.min(size.width * 0.32, 140),
      height: math.min(size.width * 0.4, 170),
    );
    final arch = RRect.fromRectAndCorners(
      window,
      topLeft: Radius.circular(window.width / 2),
      topRight: Radius.circular(window.width / 2),
    );
    canvas
      ..drawRRect(
        arch,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1B2440), Color(0xFF0E1222)],
          ).createShader(window),
      )
      // Lune.
      ..drawCircle(
        window.center.translate(window.width * 0.18, -window.height * 0.18),
        window.width * 0.12,
        Paint()..color = AriseColors.parchment.withValues(alpha: 0.85),
      );
    final frame = Paint()
      ..color = AriseColors.onGold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    canvas
      ..drawRRect(arch, frame)
      ..drawLine(
        Offset(window.center.dx, window.top + 8),
        Offset(window.center.dx, window.bottom),
        frame..strokeWidth = 4,
      )
      ..drawLine(
        Offset(window.left, window.center.dy + 10),
        Offset(window.right, window.center.dy + 10),
        frame,
      );
  }

  void _paintLanterns(Canvas canvas, Size size) {
    for (final x in [size.width * 0.2, size.width * 0.8]) {
      final top = Offset(x, size.height * 0.08 + 22);
      final body = top.translate(0, 46);
      canvas
        ..drawLine(
          top,
          body.translate(0, -12),
          Paint()
            ..color = AriseColors.stoneLight
            ..strokeWidth = 2,
        )
        ..drawCircle(
          body,
          46 * glow,
          Paint()
            ..shader = RadialGradient(
              colors: [
                AriseColors.ember.withValues(alpha: 0.45 * glow),
                AriseColors.ember.withValues(alpha: 0),
              ],
            ).createShader(Rect.fromCircle(center: body, radius: 46)),
        )
        ..drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: body, width: 16, height: 22),
            const Radius.circular(4),
          ),
          Paint()..color = Color.lerp(
            AriseColors.stoneLight,
            AriseColors.goldBright,
            glow,
          )!,
        );
    }
  }

  void _paintHearthGlow(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 1.05);
    final radius = size.height * 0.55;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AriseColors.ember.withValues(alpha: 0.55 * glow),
            AriseColors.ember.withValues(alpha: 0.12 * glow),
            AriseColors.ember.withValues(alpha: 0),
          ],
          stops: const [0, 0.5, 1],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  @override
  bool shouldRepaint(covariant _TavernPainter oldDelegate) =>
      oldDelegate.glow != glow;
}

import 'dart:math';

import 'package:arise/core/theme/arise_colors.dart';
import 'package:arise/core/theme/arise_typography.dart';
import 'package:arise/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Minuteur circulaire : anneau qui se vide et secondes restantes.
class CountdownRing extends StatelessWidget {
  const CountdownRing({
    required this.remaining,
    required this.total,
    required this.color,
    super.key,
    this.size = 168,
  });

  final Duration remaining;
  final Duration total;
  final Color color;
  final double size;

  /// Secondes affichées, arrondies au supérieur (3 → 2,1 s restantes).
  int get displayedSeconds => (remaining.inMilliseconds / 1000).ceil();

  double get progress => total.inMilliseconds == 0
      ? 0
      : (remaining.inMilliseconds / total.inMilliseconds).clamp(0, 1);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final seconds = displayedSeconds;
    final label = seconds >= 60
        ? '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}'
        : '$seconds';

    return Semantics(
      label: l10n.workoutTimerSemantics(seconds),
      liveRegion: true,
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: size,
          child: CustomPaint(
            painter: _RingPainter(progress: progress, color: color),
            child: Center(
              child: FittedBox(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: AriseTypography.display,
                      fontVariations: AriseTypography.weight(700),
                      fontSize: 56,
                      color: AriseColors.parchment,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 10.0;
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(stroke / 2);
    canvas
      ..drawArc(
        arcRect,
        0,
        2 * pi,
        false,
        Paint()
          ..color = AriseColors.stoneLight
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke,
      )
      ..drawArc(
        arcRect,
        -pi / 2,
        2 * pi * progress,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = stroke,
      );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

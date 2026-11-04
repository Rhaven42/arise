import 'dart:ui' as ui;

import 'package:arise/core/anatomy/body_shapes.dart';
import 'package:arise/core/anatomy/body_shapes_provider.dart';
import 'package:arise/core/anatomy/muscle.dart';
import 'package:arise/core/theme/arise_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Convertit un tracé décodé en `Path` Flutter.
Path pathFrom(SvgPathData data) {
  final path = Path();
  for (final command in data) {
    final a = command.args;
    switch (command.op) {
      case 'M':
        path.moveTo(a[0], a[1]);
      case 'L':
        path.lineTo(a[0], a[1]);
      case 'C':
        path.cubicTo(a[0], a[1], a[2], a[3], a[4], a[5]);
      case 'Z':
        path.close();
    }
  }
  return path;
}

/// Silhouette (face ou dos) dont les muscles sollicités sont colorés.
///
/// Si [onMuscleTap] est fourni, toucher une zone renvoie son muscle.
class BodyMap extends ConsumerWidget {
  const BodyMap({
    required this.view,
    required this.highlights,
    required this.semanticLabel,
    super.key,
    this.onMuscleTap,
  });

  final BodyView view;
  final Map<MuscleId, MuscleRole> highlights;
  final String semanticLabel;
  final ValueChanged<MuscleId>? onMuscleTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shapes = ref.watch(bodyShapesProvider).value?[view];
    if (shapes == null) {
      return const AspectRatio(aspectRatio: 200 / 450);
    }
    return Semantics(
      label: semanticLabel,
      image: true,
      child: AspectRatio(
        aspectRatio: shapes.width / shapes.height,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final painter = BodyMapPainter(
              shapes: shapes,
              highlights: highlights,
            );
            final canvas = CustomPaint(
              painter: painter,
              size: constraints.biggest,
            );
            final onTap = onMuscleTap;
            if (onTap == null) return canvas;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) {
                final muscle = painter.muscleAt(
                  details.localPosition,
                  constraints.biggest,
                );
                if (muscle != null) onTap(muscle);
              },
              child: canvas,
            );
          },
        ),
      ),
    );
  }
}

/// Dessin de la silhouette et des zones musculaires.
class BodyMapPainter extends CustomPainter {
  BodyMapPainter({required this.shapes, required this.highlights})
    : _zonePaths = {
        for (final entry in shapes.zones.entries)
          entry.key: [for (final data in entry.value) pathFrom(data)],
      },
      _outline = pathFrom(shapes.outline);

  final BodyShapes shapes;
  final Map<MuscleId, MuscleRole> highlights;
  final Map<MuscleId, List<Path>> _zonePaths;
  final Path _outline;

  double _scale(Size size) => size.width / shapes.width;

  /// Muscle situé sous [position] (coordonnées du widget), ou `null`.
  MuscleId? muscleAt(Offset position, Size size) {
    final scale = _scale(size);
    final point = position / scale;
    for (final entry in _zonePaths.entries) {
      if (entry.value.any((path) => path.contains(point))) return entry.key;
    }
    return null;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..scale(_scale(size))
      ..drawPath(_outline, Paint()..color = AriseColors.bodyFill)
      ..drawPath(
        _outline,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = AriseColors.woodLight,
      );

    for (final entry in _zonePaths.entries) {
      final role = highlights[entry.key];
      for (final path in entry.value) {
        paintMuscleZone(canvas, path, role);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant BodyMapPainter oldDelegate) =>
      oldDelegate.shapes != shapes || oldDelegate.highlights != highlights;
}

/// Peint une zone musculaire : couleur, motif selon le rôle, puis contour.
void paintMuscleZone(Canvas canvas, Path path, MuscleRole? role) {
  canvas.drawPath(path, Paint()..color = _fillFor(role));
  if (role != null) _drawPattern(canvas, path, role);
  canvas.drawPath(
    path,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6
      ..color = AriseColors.abyss,
  );
}

Color _fillFor(MuscleRole? role) => switch (role) {
    MuscleRole.primary => AriseColors.musclePrimary,
    MuscleRole.secondary => AriseColors.muscleSecondary,
    null => AriseColors.muscleIdle,
  };

/// Hachures (principal) ou points (secondaire), en plus de la couleur.
void _drawPattern(Canvas canvas, Path path, MuscleRole role) {
    final bounds = path.getBounds();
    canvas
      ..save()
      ..clipPath(path);
    switch (role) {
      case MuscleRole.primary:
        final paint = Paint()
          ..color = AriseColors.musclePrimaryPattern
          ..strokeWidth = 0.9;
        const step = 4.0;
        for (
          var x = bounds.left - bounds.height;
          x < bounds.right;
          x += step
        ) {
          canvas.drawLine(
            Offset(x, bounds.bottom),
            Offset(x + bounds.height, bounds.top),
            paint,
          );
        }
      case MuscleRole.secondary:
        final points = <Offset>[];
        const step = 4.0;
        for (var y = bounds.top + 2; y < bounds.bottom; y += step) {
          for (var x = bounds.left + 2; x < bounds.right; x += step) {
            points.add(Offset(x, y));
          }
        }
        canvas.drawPoints(
          ui.PointMode.points,
          points,
          Paint()
            ..color = AriseColors.muscleSecondaryPattern
            ..strokeWidth = 1.4
            ..strokeCap = StrokeCap.round,
        );
    }
  canvas.restore();
}

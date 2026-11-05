import 'dart:ui' as ui;

import 'package:arise/core/theme/arise_colors.dart';
import 'package:flutter/material.dart';

/// Niveau de travail d'un muscle sur la heatmap (ANATOMY.md §4).
///
/// Chaque niveau a une couleur, un motif et un libellé : la carte reste
/// lisible sans distinguer les couleurs.
enum HeatLevel {
  /// Pas du tout (gris, sans motif).
  none,

  /// Pas assez (rouge, hachures diagonales).
  low,

  /// Un peu (orange, points).
  some,

  /// Moyen (vert clair, lignes horizontales).
  medium,

  /// Très travaillé (vert vif, quadrillage).
  high,
}

Color heatColor(HeatLevel level) => switch (level) {
  HeatLevel.none => AriseColors.muscleIdle,
  HeatLevel.low => AriseColors.heatLow,
  HeatLevel.some => AriseColors.heatSome,
  HeatLevel.medium => AriseColors.muscleSecondary,
  HeatLevel.high => AriseColors.musclePrimary,
};

/// Peint une zone selon son niveau : couleur, motif, puis contour.
void paintHeatZone(Canvas canvas, Path path, HeatLevel level) {
  canvas.drawPath(path, Paint()..color = heatColor(level));
  if (level != HeatLevel.none) _drawHeatPattern(canvas, path, level);
  canvas.drawPath(
    path,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6
      ..color = AriseColors.abyss,
  );
}

void _drawHeatPattern(Canvas canvas, Path path, HeatLevel level) {
  final bounds = path.getBounds();
  final line = Paint()
    ..color = AriseColors.heatPattern
    ..strokeWidth = 0.8;
  const step = 4.0;
  canvas
    ..save()
    ..clipPath(path);
  switch (level) {
    case HeatLevel.low:
      for (var x = bounds.left - bounds.height; x < bounds.right; x += step) {
        canvas.drawLine(
          Offset(x, bounds.bottom),
          Offset(x + bounds.height, bounds.top),
          line,
        );
      }
    case HeatLevel.some:
      final points = <Offset>[
        for (var y = bounds.top + 2; y < bounds.bottom; y += step)
          for (var x = bounds.left + 2; x < bounds.right; x += step)
            Offset(x, y),
      ];
      canvas.drawPoints(
        ui.PointMode.points,
        points,
        Paint()
          ..color = AriseColors.heatPattern
          ..strokeWidth = 1.4
          ..strokeCap = StrokeCap.round,
      );
    case HeatLevel.medium:
      for (var y = bounds.top + 1; y < bounds.bottom; y += step) {
        canvas.drawLine(Offset(bounds.left, y), Offset(bounds.right, y), line);
      }
    case HeatLevel.high:
      for (var y = bounds.top + 1; y < bounds.bottom; y += step) {
        canvas.drawLine(Offset(bounds.left, y), Offset(bounds.right, y), line);
      }
      for (var x = bounds.left + 1; x < bounds.right; x += step) {
        canvas.drawLine(Offset(x, bounds.top), Offset(x, bounds.bottom), line);
      }
    case HeatLevel.none:
      break;
  }
  canvas.restore();
}

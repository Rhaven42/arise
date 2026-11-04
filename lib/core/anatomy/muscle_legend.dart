import 'package:arise/core/anatomy/body_map.dart';
import 'package:arise/core/anatomy/muscle.dart';
import 'package:arise/core/theme/arise_spacing.dart';
import 'package:arise/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Légende des rôles musculaires (couleur + motif + libellé).
class MuscleLegend extends StatelessWidget {
  const MuscleLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: AriseSpacing.lg,
      runSpacing: AriseSpacing.sm,
      children: [
        _LegendItem(role: MuscleRole.primary, label: l10n.musclePrimaryLegend),
        _LegendItem(
          role: MuscleRole.secondary,
          label: l10n.muscleSecondaryLegend,
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.role, required this.label});

  final MuscleRole role;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox.square(
          dimension: 22,
          child: CustomPaint(painter: _SwatchPainter(role)),
        ),
        const SizedBox(width: AriseSpacing.sm),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _SwatchPainter extends CustomPainter {
  const _SwatchPainter(this.role);

  final MuscleRole role;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(4)),
      );
    paintMuscleZone(canvas, path, role);
  }

  @override
  bool shouldRepaint(covariant _SwatchPainter oldDelegate) =>
      oldDelegate.role != role;
}

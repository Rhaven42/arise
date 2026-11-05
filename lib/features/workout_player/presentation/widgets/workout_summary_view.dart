import 'package:arise/core/anatomy/body_map.dart';
import 'package:arise/core/anatomy/muscle.dart';
import 'package:arise/core/anatomy/muscle_legend.dart';
import 'package:arise/core/design_system/widgets/arise_button.dart';
import 'package:arise/core/design_system/widgets/system_window.dart';
import 'package:arise/core/theme/arise_colors.dart';
import 'package:arise/core/theme/arise_spacing.dart';
import 'package:arise/core/theme/arise_typography.dart';
import 'package:arise/features/exercises/domain/exercise.dart';
import 'package:arise/features/exercises/presentation/exercise_labels.dart';
import 'package:arise/features/workout_player/domain/completed_session.dart';
import 'package:arise/features/workout_player/domain/session_summary.dart';
import 'package:arise/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Récapitulatif de fin de séance : XP, effort, muscles travaillés.
class WorkoutSummaryView extends StatelessWidget {
  const WorkoutSummaryView({
    required this.session,
    required this.exercises,
    required this.onClose,
    super.key,
  });

  final CompletedSession session;
  final Map<String, Exercise> exercises;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final roles = workedMuscles(session, exercises);
    final done = session.sets.where((s) => !s.skipped).length;

    String names(BodyView view, MuscleRole role) {
      final list = [
        for (final entry in roles.entries)
          if (entry.key.view == view && entry.value == role)
            l10n.muscle(entry.key),
      ];
      return list.isEmpty ? l10n.noneLabel : list.join(', ');
    }

    return ListView(
      padding: const EdgeInsets.all(AriseSpacing.md),
      children: [
        if (session.stoppedForPain) ...[
          _Caution(title: l10n.workoutPainTitle, body: l10n.workoutPainBody),
          const SizedBox(height: AriseSpacing.md),
        ],
        SystemWindow(
          header: l10n.systemWindowHeader,
          title: session.completed
              ? l10n.workoutSummaryTitle
              : l10n.workoutSummaryStoppedTitle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                label: l10n.workoutSummaryXpSemantics(session.xpEarned),
                child: ExcludeSemantics(
                  child: Text(
                    l10n.workoutSummaryXp(session.xpEarned),
                    style: TextStyle(
                      fontFamily: AriseTypography.display,
                      fontVariations: AriseTypography.weight(900),
                      fontSize: 40,
                      color: AriseColors.goldBright,
                      shadows: const [
                        Shadow(color: AriseColors.mana, blurRadius: 14),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AriseSpacing.sm),
              Text(
                l10n.workoutSummaryDuration(
                  session.activeSeconds ~/ 60,
                  session.activeSeconds % 60,
                ),
                style: textTheme.bodyLarge,
              ),
              Text(
                l10n.workoutSummarySets(done, session.sets.length),
                style: textTheme.bodyLarge,
              ),
              const SizedBox(height: AriseSpacing.sm),
              Text(l10n.workoutSummaryProvisional, style: textTheme.bodySmall),
            ],
          ),
        ),
        if (session.exceededDailyCap) ...[
          const SizedBox(height: AriseSpacing.md),
          _Caution(body: l10n.workoutSummaryCapWarning),
        ],
        const SizedBox(height: AriseSpacing.lg),
        Semantics(
          header: true,
          child: Text(
            l10n.workoutSummaryMuscles,
            style: textTheme.headlineSmall?.copyWith(color: AriseColors.gold),
          ),
        ),
        const SizedBox(height: AriseSpacing.sm),
        Row(
          children: [
            for (final view in BodyView.values)
              Expanded(
                child: Column(
                  children: [
                    Text(l10n.bodyViewLabel(view.name)),
                    const SizedBox(height: AriseSpacing.xs),
                    SizedBox(
                      height: 260,
                      child: BodyMap(
                        view: view,
                        highlights: roles,
                        semanticLabel: l10n.bodyMapSemantics(
                          view.name,
                          names(view, MuscleRole.primary),
                          names(view, MuscleRole.secondary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: AriseSpacing.sm),
        const MuscleLegend(),
        const SizedBox(height: AriseSpacing.xl),
        AriseButton(label: l10n.workoutSummaryClose, onPressed: onClose),
      ],
    );
  }
}

/// Encadré de prudence (douleur, dépassement du plafond quotidien).
class _Caution extends StatelessWidget {
  const _Caution({required this.body, this.title});

  final String? title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AriseColors.stoneDark,
          border: Border.all(color: AriseColors.danger, width: 2),
          borderRadius: BorderRadius.circular(AriseSpacing.radius),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AriseSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.health_and_safety, color: AriseColors.danger),
              const SizedBox(width: AriseSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title case final title?)
                      Text(
                        title,
                        style: textTheme.titleMedium?.copyWith(
                          color: AriseColors.danger,
                        ),
                      ),
                    Text(body, style: textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

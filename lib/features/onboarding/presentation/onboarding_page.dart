import 'package:arise/core/design_system/widgets/arise_button.dart';
import 'package:arise/core/design_system/widgets/system_window.dart';
import 'package:arise/core/router/app_routes.dart';
import 'package:arise/core/theme/arise_colors.dart';
import 'package:arise/core/theme/arise_spacing.dart';
import 'package:arise/core/utils/weekdays.dart';
import 'package:arise/features/onboarding/domain/onboarding_draft.dart';
import 'package:arise/features/onboarding/presentation/onboarding_controller.dart';
import 'package:arise/features/onboarding/presentation/widgets/choice_tile.dart';
import 'package:arise/features/profile/domain/player_profile.dart';
import 'package:arise/features/profile/domain/rest_days_rule.dart';
import 'package:arise/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Questionnaire de l'Éveil, une étape à la fois.
class OnboardingPage extends ConsumerWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final draft = ref.watch(onboardingControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.onboardingTitle),
        leading: BackButton(onPressed: () => context.go(AppRoutes.title)),
      ),
      body: SafeArea(
        child: switch (draft) {
          AsyncData(:final value) => _OnboardingBody(draft: value),
          AsyncError() => Center(child: Text(l10n.errorGeneric)),
          _ => const Center(
            child: CircularProgressIndicator(color: AriseColors.gold),
          ),
        },
      ),
    );
  }
}

class _OnboardingBody extends ConsumerWidget {
  const _OnboardingBody({required this.draft});

  final OnboardingDraft draft;

  Future<void> _finish(BuildContext context, WidgetRef ref) async {
    final saved = await ref
        .read(onboardingControllerProvider.notifier)
        .submit();
    // Le personnage se crée juste après le questionnaire.
    if (saved && context.mounted) context.go(AppRoutes.character);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final controller = ref.read(onboardingControllerProvider.notifier);
    final total = OnboardingStep.values.length;
    final current = draft.step.index + 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AriseSpacing.md,
            AriseSpacing.md,
            AriseSpacing.md,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.onboardingStepCounter(current, total),
                style: textTheme.labelMedium,
              ),
              const SizedBox(height: AriseSpacing.xs),
              ExcludeSemantics(
                child: LinearProgressIndicator(
                  value: current / total,
                  color: AriseColors.gold,
                  backgroundColor: AriseColors.stoneLight,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AriseSpacing.md),
            child: switch (draft.step) {
              OnboardingStep.goal => _GoalStep(draft: draft),
              OnboardingStep.level => _LevelStep(draft: draft),
              OnboardingStep.equipment => _EquipmentStep(draft: draft),
              OnboardingStep.restDays => _RestDaysStep(draft: draft),
              OnboardingStep.health => _HealthStep(draft: draft),
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AriseSpacing.md),
          child: Row(
            children: [
              if (!draft.isFirstStep) ...[
                Expanded(
                  child: AriseButton(
                    label: l10n.onboardingBack,
                    variant: AriseButtonVariant.secondary,
                    onPressed: controller.previous,
                  ),
                ),
                const SizedBox(width: AriseSpacing.sm),
              ],
              Expanded(
                flex: 2,
                child: AriseButton(
                  label: draft.isLastStep
                      ? l10n.onboardingFinish
                      : l10n.onboardingNext,
                  onPressed: !draft.canProceed
                      ? null
                      : draft.isLastStep
                      ? () => _finish(context, ref)
                      : controller.next,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Titre d'une étape, annoncé comme en-tête au lecteur d'écran.
class _StepQuestion extends StatelessWidget {
  const _StepQuestion(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AriseSpacing.md),
      child: Semantics(
        header: true,
        child: Text(text, style: Theme.of(context).textTheme.headlineSmall),
      ),
    );
  }
}

class _GoalStep extends ConsumerWidget {
  const _GoalStep({required this.draft});

  final OnboardingDraft draft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(onboardingControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepQuestion(l10n.onboardingGoalQuestion),
        for (final goal in FitnessGoal.values)
          ChoiceTile(
            title: l10n.goalLabel(goal.name),
            description: l10n.goalDescription(goal.name),
            selected: draft.goal == goal,
            onTap: () => controller.selectGoal(goal),
          ),
      ],
    );
  }
}

class _LevelStep extends ConsumerWidget {
  const _LevelStep({required this.draft});

  final OnboardingDraft draft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(onboardingControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepQuestion(l10n.onboardingLevelQuestion),
        for (final level in FitnessLevel.values)
          ChoiceTile(
            title: l10n.levelLabel(level.name),
            description: l10n.levelDescription(level.name),
            selected: draft.level == level,
            onTap: () => controller.selectLevel(level),
          ),
      ],
    );
  }
}

class _EquipmentStep extends ConsumerWidget {
  const _EquipmentStep({required this.draft});

  final OnboardingDraft draft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(onboardingControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepQuestion(l10n.onboardingEquipmentQuestion),
        Text(
          l10n.onboardingEquipmentHint,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AriseSpacing.md),
        Wrap(
          spacing: AriseSpacing.sm,
          runSpacing: AriseSpacing.sm,
          children: [
            for (final item in Equipment.values)
              FilterChip(
                label: Text(l10n.equipmentLabel(item.name)),
                selected: draft.equipment.contains(item),
                onSelected: (_) => controller.toggleEquipment(item),
              ),
          ],
        ),
      ],
    );
  }
}

class _RestDaysStep extends ConsumerWidget {
  const _RestDaysStep({required this.draft});

  final OnboardingDraft draft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(onboardingControllerProvider.notifier);
    final canAdd = RestDaysRule.canAddMore(draft.restDays);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepQuestion(l10n.onboardingRestQuestion),
        Text(
          l10n.onboardingRestHint(RestDaysRule.minDays, RestDaysRule.maxDays),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AriseSpacing.md),
        Wrap(
          spacing: AriseSpacing.sm,
          runSpacing: AriseSpacing.sm,
          children: [
            for (
              var day = RestDaysRule.firstWeekday;
              day <= RestDaysRule.lastWeekday;
              day++
            )
              _RestDayChip(
                day: day,
                selected: draft.restDays.contains(day),
                enabled: canAdd || draft.restDays.contains(day),
                onToggle: controller.toggleRestDay,
              ),
          ],
        ),
        const SizedBox(height: AriseSpacing.md),
        Text(
          l10n.onboardingRestCount(draft.restDays.length),
          style: Theme.of(context).textTheme.labelMedium,
        ),
      ],
    );
  }
}

class _RestDayChip extends StatelessWidget {
  const _RestDayChip({
    required this.day,
    required this.selected,
    required this.enabled,
    required this.onToggle,
  });

  final int day;
  final bool selected;
  final bool enabled;
  final Future<void> Function(int day) onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FilterChip(
      label: Text(l10n.weekdayLong(weekdayKey(day))),
      selected: selected,
      onSelected: enabled ? (_) => onToggle(day) : null,
    );
  }
}

class _HealthStep extends ConsumerWidget {
  const _HealthStep({required this.draft});

  final OnboardingDraft draft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final controller = ref.read(onboardingControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepQuestion(l10n.onboardingHealthQuestion),
        SystemWindow(
          header: l10n.systemWindowHeader,
          title: l10n.safetyTitle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.safetyBody, style: textTheme.bodyLarge),
              const SizedBox(height: AriseSpacing.sm),
              // Material transparent : la case est posée sur le fond décoré
              // de la fenêtre du Système.
              Material(
                type: MaterialType.transparency,
                child: CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: draft.safetyAcknowledged,
                  onChanged: (value) =>
                      controller.setSafetyAcknowledged(value: value ?? false),
                  title: Text(l10n.safetyAcknowledge),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AriseSpacing.lg),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: draft.healthConsent,
          onChanged: (value) => controller.setHealthConsent(value: value),
          title: Text(l10n.healthConsentTitle),
          subtitle: Text(l10n.healthConsentBody),
        ),
      ],
    );
  }
}

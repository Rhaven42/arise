import 'dart:async';

import 'package:arise/core/config/game_config.dart';
import 'package:arise/core/design_system/widgets/arise_button.dart';
import 'package:arise/core/design_system/widgets/stone_frame.dart';
import 'package:arise/core/theme/arise_colors.dart';
import 'package:arise/core/theme/arise_spacing.dart';
import 'package:arise/features/exercises/domain/stat_id.dart';
import 'package:arise/features/health/domain/health_log.dart';
import 'package:arise/features/health/presentation/health_providers.dart';
import 'package:arise/features/profile/presentation/profile_providers.dart';
import 'package:arise/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Santé : pas, activités et sommeil lus sur le téléphone (lecture seule),
/// verres d'eau, et l'XP de stat qu'ils rapportent.
class HealthPage extends ConsumerStatefulWidget {
  const HealthPage({super.key});

  static const consentKey = Key('health-consent');
  static const syncKey = Key('health-sync');
  static const addGlassKey = Key('health-add-glass');
  static const removeGlassKey = Key('health-remove-glass');

  @override
  ConsumerState<HealthPage> createState() => _HealthPageState();
}

class _HealthPageState extends ConsumerState<HealthPage> {
  @override
  void initState() {
    super.initState();
    // Lecture du téléphone à l'ouverture, si le joueur l'a autorisée.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final profile = await ref.read(playerProfileProvider.future);
      if (mounted && (profile?.healthConsent ?? false)) {
        unawaited(ref.read(healthControllerProvider.notifier).sync());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final view = ref.watch(healthControllerProvider).value;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.healthTitle)),
      body: view == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AriseSpacing.md),
              children: [
                _ConsentCard(view: view),
                const SizedBox(height: AriseSpacing.md),
                _TodayCard(view: view),
                const SizedBox(height: AriseSpacing.md),
                _WaterCard(day: view.today),
                const SizedBox(height: AriseSpacing.md),
                _HistoryCard(log: view.log),
                const SizedBox(height: AriseSpacing.md),
                Text(
                  l10n.healthRestNote,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
    );
  }
}

class _ConsentCard extends ConsumerWidget {
  const _ConsentCard({required this.view});

  final HealthView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(playerProfileProvider).value;
    final consent = profile?.healthConsent ?? false;
    final status = switch (view.status) {
      HealthSyncStatus.denied => l10n.healthStatusDenied,
      HealthSyncStatus.failed => l10n.healthStatusFailed,
      HealthSyncStatus.synced => l10n.healthStatusSynced,
      HealthSyncStatus.disabled || HealthSyncStatus.idle => null,
    };
    return StoneFrame(
      padding: const EdgeInsets.all(AriseSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwitchListTile(
            key: HealthPage.consentKey,
            contentPadding: EdgeInsets.zero,
            value: consent,
            onChanged: profile == null
                ? null
                : (value) => ref
                      .read(profileRepositoryProvider)
                      .saveProfile(profile.copyWith(healthConsent: value)),
            title: Text(l10n.healthConsentTitle),
            subtitle: Text(l10n.healthReadOnlyHint),
          ),
          if (consent) ...[
            const SizedBox(height: AriseSpacing.xs),
            AriseButton(
              key: HealthPage.syncKey,
              label: l10n.healthSync,
              icon: Icons.sync,
              variant: AriseButtonVariant.secondary,
              onPressed: () =>
                  unawaited(ref.read(healthControllerProvider.notifier).sync()),
            ),
          ],
          if (status != null) ...[
            const SizedBox(height: AriseSpacing.xs),
            Semantics(liveRegion: true, child: Text(status)),
          ],
        ],
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.view});

  final HealthView view;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final day = view.today;
    final c = gameConfig.health;
    final xp = view.todayXp;
    return StoneFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(l10n.healthToday, style: textTheme.titleLarge),
          ),
          const SizedBox(height: AriseSpacing.sm),
          _Metric(
            icon: Icons.directions_walk,
            label: l10n.healthSteps,
            value: l10n.healthStepsValue(day.steps),
            progress: day.steps / c.stepsCap,
          ),
          _Metric(
            icon: Icons.directions_run,
            label: l10n.healthActivity,
            value: l10n.healthMinutes(day.activityMinutes),
            progress: day.activityMinutes / c.activityMinutesCap,
          ),
          _Metric(
            icon: Icons.bedtime_outlined,
            label: l10n.healthSleep,
            value: l10n.healthSleepValue(
              day.sleepMinutes ~/ 60,
              day.sleepMinutes % 60,
            ),
            progress: day.sleepMinutes / (c.sleepBonusMinHours * 60),
          ),
          const SizedBox(height: AriseSpacing.sm),
          Text(
            xp.isEmpty
                ? l10n.healthNoXpYet
                : l10n.healthXpToday(
                    xp[StatId.endurance] ?? 0,
                    xp[StatId.vitality] ?? 0,
                  ),
            style: textTheme.bodyMedium?.copyWith(color: AriseColors.gold),
          ),
          Text(
            l10n.healthRules(
              c.xpPerStepBlock,
              c.stepsPerBlock,
              c.sleepBonusMinHours,
              c.sleepBonusXp,
            ),
            style: textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.icon,
    required this.label,
    required this.value,
    required this.progress,
  });

  final IconData icon;
  final String label;
  final String value;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      label: '$label : $value',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AriseSpacing.xs),
        child: Row(
          children: [
            Icon(icon, color: AriseColors.gold),
            const SizedBox(width: AriseSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(label, style: textTheme.bodyMedium)),
                      Text(value, style: textTheme.titleSmall),
                    ],
                  ),
                  const SizedBox(height: AriseSpacing.xs),
                  LinearProgressIndicator(
                    value: progress.clamp(0, 1).toDouble(),
                    color: AriseColors.gold,
                    backgroundColor: AriseColors.parchmentMuted.withValues(
                      alpha: 0.25,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WaterCard extends ConsumerWidget {
  const _WaterCard({required this.day});

  final HealthDay day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final c = gameConfig.health;
    final controller = ref.read(healthControllerProvider.notifier);
    return StoneFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(l10n.healthWater, style: textTheme.titleLarge),
          ),
          const SizedBox(height: AriseSpacing.xs),
          Row(
            children: [
              IconButton(
                key: HealthPage.removeGlassKey,
                tooltip: l10n.healthRemoveGlass,
                onPressed: day.glasses > 0
                    ? () => unawaited(controller.addGlass(-1))
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    l10n.healthGlasses(
                      day.glasses,
                      c.hydrationGoalGlasses,
                      day.glasses * c.glassMl,
                    ),
                    textAlign: TextAlign.center,
                    style: textTheme.titleMedium,
                  ),
                ),
              ),
              IconButton(
                key: HealthPage.addGlassKey,
                tooltip: l10n.healthAddGlass,
                onPressed: day.glasses < c.maxGlasses
                    ? () => unawaited(controller.addGlass(1))
                    : null,
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          Text(
            l10n.healthWaterHint(c.hydrationGoalGlasses, c.hydrationBonusXp),
            style: textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.log});

  final HealthLog log;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final days = log.days.reversed.take(7).toList();
    return StoneFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(l10n.healthHistory, style: textTheme.titleLarge),
          ),
          if (days.isEmpty)
            Text(l10n.healthHistoryEmpty, style: textTheme.bodyMedium),
          for (final d in days)
            Padding(
              padding: const EdgeInsets.only(top: AriseSpacing.xs),
              child: Text(
                l10n.healthHistoryLine(
                  DateTime(d.day.year, d.day.month, d.day.day),
                  d.steps,
                  d.sleepMinutes ~/ 60,
                  d.glasses,
                ),
                style: textTheme.bodyMedium,
              ),
            ),
        ],
      ),
    );
  }
}

import 'dart:async';

import 'package:arise/core/config/game_config.dart';
import 'package:arise/core/router/app_routes.dart';
import 'package:arise/core/theme/arise_colors.dart';
import 'package:arise/core/theme/arise_spacing.dart';
import 'package:arise/core/utils/clock.dart';
import 'package:arise/features/profile/presentation/profile_providers.dart';
import 'package:arise/features/progression/domain/civil_date.dart';
import 'package:arise/features/progression/presentation/progression_labels.dart';
import 'package:arise/features/progression/presentation/progression_providers.dart';
import 'package:arise/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Paramètres : consentement santé, sauvegarde et données.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(playerProfileProvider).value;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AriseSpacing.sm),
        children: [
          _SectionHeader(l10n.settingsHealthSection),
          SwitchListTile(
            value: profile?.healthConsent ?? false,
            onChanged: profile == null
                ? null
                : (value) => ref
                      .read(profileRepositoryProvider)
                      .saveProfile(profile.copyWith(healthConsent: value)),
            title: Text(l10n.healthConsentTitle),
            subtitle: Text(l10n.settingsHealthConsentHint),
          ),
          const Divider(),
          _SectionHeader(l10n.settingsSickSection),
          const _SickModeTile(),
          const Divider(),
          _SectionHeader(l10n.settingsWorkoutSection),
          SwitchListTile(
            value: profile?.workoutSounds ?? true,
            onChanged: profile == null
                ? null
                : (value) => ref
                      .read(profileRepositoryProvider)
                      .saveProfile(profile.copyWith(workoutSounds: value)),
            title: Text(l10n.settingsWorkoutSounds),
          ),
          SwitchListTile(
            value: profile?.workoutVoice ?? false,
            onChanged: profile == null
                ? null
                : (value) => ref
                      .read(profileRepositoryProvider)
                      .saveProfile(profile.copyWith(workoutVoice: value)),
            title: Text(l10n.settingsWorkoutVoice),
            subtitle: Text(l10n.settingsWorkoutVoiceHint),
          ),
          const Divider(),
          _SectionHeader(l10n.settingsBackupSection),
          ListTile(
            leading: const Icon(Icons.save_alt, color: AriseColors.gold),
            title: Text(l10n.settingsBackupTile),
            subtitle: Text(l10n.settingsBackupTileHint),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRoutes.backup),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AriseSpacing.md,
        AriseSpacing.md,
        AriseSpacing.md,
        AriseSpacing.xs,
      ),
      child: Semantics(
        header: true,
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(color: AriseColors.gold),
        ),
      ),
    );
  }
}

/// Mode maladie ou blessure : pause sans pénalité (1 à 14 jours).
class _SickModeTile extends ConsumerWidget {
  const _SickModeTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(progressionControllerProvider).value?.state;
    final now = ref.watch(clockProvider)();
    final controller = ref.read(progressionControllerProvider.notifier);
    final until = state?.sickUntil;
    final active = state != null && state.isSickOn(CivilDate.ofLocal(now));

    if (active && until != null) {
      return ListTile(
        leading: const Icon(Icons.healing, color: AriseColors.mana),
        title: Text(l10n.settingsSickActive(formatCivilDate(until))),
        subtitle: Text(l10n.settingsSickHint),
        trailing: TextButton(
          onPressed: () => unawaited(controller.stopSickMode()),
          child: Text(l10n.settingsSickStop),
        ),
      );
    }
    return ListTile(
      leading: const Icon(Icons.healing_outlined, color: AriseColors.gold),
      title: Text(l10n.settingsSickStart),
      subtitle: Text(l10n.settingsSickHint),
      enabled: state != null,
      onTap: () async {
        final days = await showDialog<int>(
          context: context,
          builder: (_) => const _SickDaysDialog(),
        );
        if (days != null) await controller.startSickMode(days);
      },
    );
  }
}

class _SickDaysDialog extends StatefulWidget {
  const _SickDaysDialog();

  @override
  State<_SickDaysDialog> createState() => _SickDaysDialogState();
}

class _SickDaysDialogState extends State<_SickDaysDialog> {
  int _days = 3;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final max = gameConfig.rest.sickModeMaxDays;
    return AlertDialog(
      title: Text(l10n.settingsSickDialogTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.settingsSickDays(_days),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Slider(
            value: _days.toDouble(),
            min: 1,
            max: max.toDouble(),
            divisions: max - 1,
            label: l10n.settingsSickDays(_days),
            onChanged: (value) => setState(() => _days = value.round()),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelAction),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_days),
          child: Text(l10n.settingsSickConfirm),
        ),
      ],
    );
  }
}

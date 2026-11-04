import 'package:arise/core/router/app_routes.dart';
import 'package:arise/core/theme/arise_colors.dart';
import 'package:arise/core/theme/arise_spacing.dart';
import 'package:arise/features/profile/presentation/profile_providers.dart';
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
          _SectionHeader(l10n.settingsBackupSection),
          ListTile(
            leading: const Icon(Icons.save_alt, color: AriseColors.gold),
            title: Text(l10n.settingsBackupSection),
            subtitle: Text(l10n.settingsBackupHint),
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
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AriseColors.gold,
          ),
        ),
      ),
    );
  }
}

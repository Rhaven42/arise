import 'package:arise/core/design_system/widgets/arise_button.dart';
import 'package:arise/core/router/app_routes.dart';
import 'package:arise/core/theme/arise_colors.dart';
import 'package:arise/core/theme/arise_spacing.dart';
import 'package:arise/features/backup/presentation/backup_flows.dart';
import 'package:arise/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Sauvegarde et données : export, restauration, effacement.
class BackupPage extends ConsumerWidget {
  const BackupPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsBackupSection)),
      body: ListView(
        padding: const EdgeInsets.all(AriseSpacing.md),
        children: [
          Text(l10n.settingsBackupHint, style: textTheme.bodyLarge),
          const SizedBox(height: AriseSpacing.lg),
          AriseButton(
            label: l10n.settingsExport,
            icon: Icons.ios_share,
            onPressed: () => runExportFlow(context, ref),
          ),
          const SizedBox(height: AriseSpacing.sm),
          AriseButton(
            label: l10n.settingsImport,
            icon: Icons.restore,
            variant: AriseButtonVariant.secondary,
            onPressed: () => runRestoreFlow(context, ref),
          ),
          const SizedBox(height: AriseSpacing.xl),
          Semantics(
            header: true,
            child: Text(
              l10n.settingsDataSection,
              style: textTheme.titleMedium?.copyWith(color: AriseColors.gold),
            ),
          ),
          const SizedBox(height: AriseSpacing.sm),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AriseColors.danger,
              side: const BorderSide(color: AriseColors.danger),
            ),
            icon: const Icon(Icons.delete_forever_outlined),
            label: Text(l10n.settingsErase),
            onPressed: () async {
              final erased = await runEraseFlow(context, ref);
              if (erased && context.mounted) context.go(AppRoutes.title);
            },
          ),
        ],
      ),
    );
  }
}

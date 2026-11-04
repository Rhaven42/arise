import 'package:arise/core/design_system/widgets/arise_button.dart';
import 'package:arise/core/router/app_routes.dart';
import 'package:arise/core/theme/arise_spacing.dart';
import 'package:arise/features/backup/presentation/backup_flows.dart';
import 'package:arise/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Restauration d'une sauvegarde depuis l'écran titre (nouveau téléphone).
class RestorePage extends ConsumerWidget {
  const RestorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.titleRestoreButton),
        leading: BackButton(onPressed: () => context.go(AppRoutes.title)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AriseSpacing.md),
        children: [
          Text(
            l10n.settingsBackupHint,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AriseSpacing.lg),
          AriseButton(
            label: l10n.settingsImport,
            icon: Icons.folder_open,
            onPressed: () async {
              final restored = await runRestoreFlow(context, ref);
              if (restored && context.mounted) {
                context.go(AppRoutes.systemHome);
              }
            },
          ),
        ],
      ),
    );
  }
}

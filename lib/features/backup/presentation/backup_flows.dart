import 'package:arise/features/backup/presentation/backup_controller.dart';
import 'package:arise/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void _notify(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

Future<bool> _confirm(
  BuildContext context, {
  required String title,
  required String body,
  required String action,
}) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancelAction),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(action),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

/// Choix d'un fichier, validation, confirmation puis restauration.
///
/// Renvoie `true` si les données ont été restaurées.
Future<bool> runRestoreFlow(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final controller = ref.read(backupControllerProvider.notifier);

  final picked = await controller.pickBackup();
  if (!context.mounted) return false;

  switch (picked) {
    case BackupPickCancelled():
      return false;
    case BackupPickInvalid(:final error):
      _notify(context, l10n.backupErrorMessage(error.name));
      return false;
    case BackupPickReady(:final data):
      final date = MaterialLocalizations.of(context)
          .formatFullDate(data.exportedAt.toLocal());
      final confirmed = await _confirm(
        context,
        title: l10n.restoreConfirmTitle,
        body: l10n.restoreConfirmBody(date),
        action: l10n.restoreConfirmAction,
      );
      if (!confirmed) return false;
      await controller.restore(data);
      if (context.mounted) _notify(context, l10n.restoreSuccess);
      return true;
  }
}

/// Export de toutes les données via la feuille de partage.
Future<void> runExportFlow(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final shared = await ref
      .read(backupControllerProvider.notifier)
      .exportBackup();
  if (shared && context.mounted) _notify(context, l10n.exportSuccess);
}

/// Effacement de toutes les données, après confirmation.
///
/// Renvoie `true` si les données ont été effacées.
Future<bool> runEraseFlow(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await _confirm(
    context,
    title: l10n.eraseConfirmTitle,
    body: l10n.eraseConfirmBody,
    action: l10n.eraseConfirmAction,
  );
  if (!confirmed) return false;
  await ref.read(backupControllerProvider.notifier).eraseAll();
  if (context.mounted) _notify(context, l10n.eraseSuccess);
  return true;
}

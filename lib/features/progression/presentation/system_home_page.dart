import 'package:arise/core/design_system/widgets/system_window.dart';
import 'package:arise/core/theme/arise_spacing.dart';
import 'package:arise/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Fenêtre du Système (tableau de bord complet en phase 4).
class SystemHomePage extends StatelessWidget {
  const SystemHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.systemHomeTitle)),
      body: Padding(
        padding: const EdgeInsets.all(AriseSpacing.md),
        child: SystemWindow(
          header: l10n.systemWindowHeader,
          title: l10n.systemHomeTitle,
          child: Text(l10n.systemHomeBody),
        ),
      ),
    );
  }
}
